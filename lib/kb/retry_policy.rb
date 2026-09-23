require 'socket'
require 'net/http'

module KB
  # Decides which failed KB calls the client retries.
  #
  # Two classes of transport failure, told apart by the underlying Ruby error
  # rather than the Faraday class (adapters disagree on the Faraday class: the
  # net_http adapter wraps Net::OpenTimeout as ConnectionFailed, the persistent
  # one as TimeoutError):
  #
  # - never sent: TCP connect / TLS handshake did not complete, so KB cannot have
  #   seen the request. Safe to retry for every verb, POST included.
  # - maybe sent: anything else the transport raises (read/write timeout, reset,
  #   EOF, TLS error mid-stream). KB may have processed it, so only GET is retried.
  #   PUT/DELETE are left out on purpose: `upsert` and `merge!` are PUTs whose
  #   second run is not a no-op on KB's side.
  #
  # HTTP responses (4xx/5xx) are never retried: KB answered.
  module RetryPolicy
    NOT_SENT_ERRORS = [
      Net::OpenTimeout,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Errno::EADDRNOTAVAIL,
      SocketError # DNS resolution
    ].freeze
    TRANSPORT_ERRORS = [Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError].freeze
    MAYBE_SENT_VERBS = %i[get head].freeze

    module_function

    def retry?(verb, error)
      return false unless TRANSPORT_ERRORS.any? { |klass| error.is_a?(klass) }

      not_sent?(error) || MAYBE_SENT_VERBS.include?(verb)
    end

    def not_sent?(error)
      cause = root_cause(error)
      NOT_SENT_ERRORS.any? { |klass| cause.is_a?(klass) }
    end

    def root_cause(error)
      (error.respond_to?(:wrapped_exception) && error.wrapped_exception) || error.cause || error
    end

    # Options for faraday-retry's middleware, read from KB.config.request.
    def middleware_options
      {
        max: KB.config.request.retries,
        interval: KB.config.request.retry_interval,
        interval_randomness: 1, # 1x-2x the interval, so a burst of callers doesn't retry in lockstep
        exceptions: TRANSPORT_ERRORS,
        methods: [], # always ask retry_if
        retry_if: ->(env, error) { retry?(env[:method], error) },
        retry_block: ->(env, _options, _retries_left, error) { record(env, error) }
      }
    end

    # Hands the request.kb_client event payload to the middleware through the
    # request context, so each retry is reported on the call's own event.
    def track(request, event)
      request.options.context = { kb_event: event }
    end

    def record(env, error)
      event = env[:request].context&.dig(:kb_event)
      return unless event

      event[:retries] = event.fetch(:retries, 0) + 1
      (event[:retry_errors] ||= []) << root_cause(error).class.name
    end
  end
end
