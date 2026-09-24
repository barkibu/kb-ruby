require 'faraday/net_http_persistent'

module KB
  # The Faraday connections behind every KB::Client, shared per process.
  #
  # Each model class has its own KB::Client (PetParent, Pet, Breed...). Sharing
  # one Faraday connection between them means one adapter instance, so with
  # keep-alive (the stock faraday-net_http_persistent adapter) one connection
  # pool serves every client. Clients send full URLs and their own API key per
  # request, so nothing on the connection is specific to one client; the pool
  # keeps its sockets per host and port.
  #
  # Two connections:
  # - keep-alive, for every call on the global timeouts;
  # - plain net_http (a new connection per call), for calls that set their own
  #   `read_timeout:`. The persistent adapter writes each call's timeouts onto the
  #   shared pool object, where any thread's next checkout reads them, so a
  #   per-call override there would leak into other threads' calls.
  #
  # Built on first use from KB.config; `reset!` applies later config changes.
  module Connections
    MUTEX = Mutex.new
    @connections = {}

    class << self
      def fetch(keep_alive:)
        @connections[keep_alive] || MUTEX.synchronize { @connections[keep_alive] ||= build(keep_alive) }
      end

      def reset!
        MUTEX.synchronize { @connections = {} }
      end

      private

      def build(keep_alive)
        Faraday.new(headers: { 'Content-Type': 'application/json' }, request: timeouts) do |conn|
          conn.request :retry, RetryPolicy.middleware_options
          conn.response :json
          conn.response :raise_error
          log(conn) if KB.config.log_level == :debugger
          adapter(conn, keep_alive)
        end
      end

      # The block runs on every request, on the shared Net::HTTP::Persistent.
      # faraday-net_http's configure_request also sets max_retries = 0 there, so
      # Net::HTTP never retries on its own: retries belong to KB::RetryPolicy.
      def adapter(conn, keep_alive)
        return conn.adapter(:net_http) unless keep_alive

        conn.adapter(:net_http_persistent) { |http| http.idle_timeout = KB.config.request.idle_timeout }
      end

      def log(conn)
        conn.response :logger do |logger|
          logger.filter(/(X-api-key:\s)("\w+")/, '\1[API_KEY_SCRUBBED]')
        end
      end

      def timeouts
        {
          open_timeout: KB.config.request.connect_timeout,
          write_timeout: KB.config.request.write_timeout,
          read_timeout: KB.config.request.read_timeout
        }
      end
    end
  end
end
