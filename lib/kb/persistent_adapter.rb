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
  #   "reused" means the pool handed out an already-open connection. Net::HTTP may
  #   still reconnect it silently if it sees the peer closed it; a failure that
  #   never reached KB (connect timeout, refused) is always reported as "new".
  #
  # Differences from faraday-net_http, on purpose: connect_timeout and
  # idle_timeout are read once per process, when the shared pool is built (call
  # `reset!` after changing them at runtime), and HTTP(S)_PROXY is not honoured.
  class PersistentAdapter < Faraday::Adapter::NetHttpPersistent
    CURRENT_ATTEMPT = :kb_persistent_attempt
    MUTEX = Mutex.new

    class << self
      def http
        @http || MUTEX.synchronize { @http ||= build_http }
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
    Attempt = Struct.new(:options, :connection, :error) do
      def apply(persistent_connection)
        apply_timeouts(persistent_connection.http)
        self.connection = persistent_connection.requests.zero? ? 'new' : 'reused'
      end

      def apply_timeouts(http)
        http.open_timeout = options.open_timeout if options.open_timeout # Net::HTTP's own reconnects
        http.read_timeout = options.read_timeout if options.read_timeout
        http.write_timeout = options.write_timeout if options.write_timeout
      end

      # A failure before a connection was handed out, or one that never reached
      # KB, happened while opening a connection.
      def label
        return 'new' if connection.nil? || (error && RetryPolicy.not_sent?(error))

        connection
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
    rescue StandardError => e
      attempt.error = e
      raise normalize(e)
    ensure
      Thread.current[CURRENT_ATTEMPT] = nil
      record(env, attempt)
    end

    # Gives the Faraday errors faraday-net_http gives for the same failure. The
    # stock adapter's perform_request rescues first and differs in two ways:
    # - Net::OpenTimeout becomes TimeoutError; faraday-net_http says ConnectionFailed.
    # - "connection refused" / "host down" arrive as Net::HTTP::Persistent::Error,
    #   with the real Errno as its `cause`. The stock adapter wraps it (refused)
    #   or re-raises it raw (host down, not a Faraday error at all). Here it
    #   becomes ConnectionFailed wrapping the Errno, so RetryPolicy.root_cause
    #   finds it one level down.
    def normalize(error)
      cause = error.is_a?(Faraday::Error) ? error.wrapped_exception : error
      return Faraday::ConnectionFailed.new(cause) if cause.is_a?(Net::OpenTimeout)
      return Faraday::ConnectionFailed.new(cause.cause || cause) if cause.is_a?(Net::HTTP::Persistent::Error)

      error
    end

    def record(env, attempt)
      event = env[:request].context&.dig(:kb_event)
      (event[:connections] ||= []) << attempt.label if event && attempt
    end
  end
end
