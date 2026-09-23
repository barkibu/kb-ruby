require 'faraday/net_http_persistent'
require 'net/http/persistent'

module KB
  # Keep-alive transport for KB calls: faraday-net_http_persistent 1.2 with the
  # fixes it needs to be a drop-in for the net_http adapter.
  #
  # - One Net::HTTP::Persistent per process, shared by every KB::Client. Each
  #   model class memoizes its own client, but the pool is keyed by host and
  #   port, so all of them reuse the same connections to KB.
  # - Timeouts go on the checked-out connection, never on the shared
  #   Net::HTTP::Persistent. The stock adapter writes every request's timeouts
  #   onto the shared object, so one call's `read_timeout:` override (e.g. 30s
  #   for birthdays) would leak into whatever another thread sends next.
  # - SSL is left to Net::HTTP::Persistent's defaults (see #configure_ssl).
  # - Error classes match the net_http adapter: a connect timeout stays
  #   Faraday::ConnectionFailed (the stock adapter raises TimeoutError), and
  #   Net::HTTP::Persistent::Error ("connection refused", "host down") becomes
  #   Faraday::ConnectionFailed wrapping the underlying Errno instead of leaking
  #   raw past KB::Error.
  # - Each attempt reports whether it opened a new connection or reused one, into
  #   the request.kb_client event as `connections` (e.g. ["reused", "new"]).
  class PersistentAdapter < Faraday::Adapter::NetHttpPersistent
    CURRENT_ATTEMPT = :kb_persistent_attempt
    MUTEX = Mutex.new

    class << self
      def http
        MUTEX.synchronize { @http ||= build_http }
      end

      # Closes every pooled connection; the next call builds a fresh pool with
      # the current KB.config.
      def reset!
        MUTEX.synchronize do
          @http&.shutdown
          @http = nil
        end
      end

      private

      def build_http
        HTTP.new(name: 'kb-ruby').tap do |http|
          http.idle_timeout = KB.config.request.idle_timeout
          http.open_timeout = KB.config.request.connect_timeout
          http.max_retries = 0 # retries belong to KB::RetryPolicy
        end
      end
    end

    # One request's view of the connection it was given.
    Attempt = Struct.new(:options, :connection) do
      def apply(persistent_connection)
        http = persistent_connection.http
        http.read_timeout = options.read_timeout if options.read_timeout
        http.write_timeout = options.write_timeout if options.write_timeout
        self.connection = persistent_connection.requests.zero? ? 'new' : 'reused'
      end
    end

    class HTTP < Net::HTTP::Persistent
      def connection_for(uri)
        super do |connection|
          Thread.current[CURRENT_ATTEMPT]&.apply(connection)
          yield connection
        end
      end
    end

    private

    def net_http_connection(_env)
      self.class.http
    end

    # Timeouts are applied per checked-out connection (see Attempt#apply).
    def configure_request(_http, _req); end

    # KB clients pass no SSL options, and Net::HTTP::Persistent's defaults are
    # the same as Faraday's (VERIFY_PEER, system CA store). The stock method would
    # set a cert store object per adapter instance, i.e. per model client, and
    # every change of store object makes Net::HTTP::Persistent drop all TLS
    # connections, so alternating model clients would never reuse one.
    def configure_ssl(_http, _ssl); end

    def perform_request(http, env)
      attempt = Attempt.new(env[:request])
      Thread.current[CURRENT_ATTEMPT] = attempt
      super
    rescue Faraday::Error, Net::HTTP::Persistent::Error => e
      raise normalize(e)
    ensure
      Thread.current[CURRENT_ATTEMPT] = nil
      record(env, attempt)
    end

    def normalize(error)
      cause = error.is_a?(Faraday::Error) ? error.wrapped_exception : error
      return Faraday::ConnectionFailed.new(cause) if cause.is_a?(Net::OpenTimeout)
      return Faraday::ConnectionFailed.new(cause.cause || cause) if cause.is_a?(Net::HTTP::Persistent::Error)

      error
    end

    # A failure before a connection was handed out happened while opening one.
    def record(env, attempt)
      event = env[:request].context&.dig(:kb_event)
      (event[:connections] ||= []) << (attempt.connection || 'new') if event && attempt
    end
  end
end
