require 'socket'
require 'net/http'
require 'faraday/retry'

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
  #   EOF, TLS error mid-stream). KB may have processed it, so only GET/HEAD are
  #   retried. PUT/DELETE are left out on purpose: `upsert` and `merge!` are PUTs
  #   whose second run is not a no-op on KB's side, and a repeated DELETE would
  #   turn a success into a 404.
  #   A call that raised its own read budget (`read_timeout:`, e.g. 30s for
  #   birthdays) is not retried on these either, so its worst case isn't doubled.
  #
  # HTTP responses (4xx/5xx) are never retried: KB answered.
  module RetryPolicy
    NOT_SENT_ERRORS = [
      Net::OpenTimeout,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ENETUNREACH,
      Errno::EADDRNOTAVAIL,
      Errno::EHOSTDOWN,
      SocketError # DNS resolution
    ].freeze
    TRANSPORT_ERRORS = [Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError].freeze
    MAYBE_SENT_VERBS = %i[get head].freeze

    module_function

    def retry?(verb, error, own_read_budget: false)
      return false unless TRANSPORT_ERRORS.any? { |klass| error.is_a?(klass) }

      not_sent?(error) || (MAYBE_SENT_VERBS.include?(verb) && !own_read_budget)
    end

    def not_sent?(error)
      cause = root_cause(error)
      NOT_SENT_ERRORS.any? { |klass| cause.is_a?(klass) }
    end

    # The Ruby error behind a Faraday error. `wrapped_exception` is Faraday's own
    # explicit link to it (Ruby's `cause` is only whatever was being rescued at
    # the raise, usually the same object). Faraday's adapters wrap the Ruby error
    # one level deep, so one level is enough.
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
        retry_if: lambda do |env, error|
          retry?(env[:method], error, own_read_budget: env[:request].context&.dig(:kb_own_read_budget))
        end,
        retry_block: ->(env, _options, _retries_left, error) { record(env, error) }
      }
    end

    # Hands the request.kb_client event payload (and whether the call set its own
    # read budget) to the middleware through the request context, so each retry
    # is reported on the call's own event.
    def track(request, event, read_timeout = nil)
      tracking = { kb_event: event, kb_own_read_budget: !read_timeout.nil? }
      request.options.context = (request.options.context || {}).merge(tracking)
    end

    def record(env, error)
      event = env[:request].context&.dig(:kb_event)
      return unless event

      event[:retries] = event.fetch(:retries, 0) + 1
      (event[:retry_errors] ||= []) << root_cause(error).class.name
    end
  end
end
