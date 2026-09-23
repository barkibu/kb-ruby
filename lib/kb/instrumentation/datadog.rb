require 'uri'
require 'active_support/notifications'

module KB
  module Instrumentation
    # Opt-in Datadog APM tracing for every KB call, as a subscriber to the
    # client's `request.kb_client` notification.
    #
    #   # config/initializers/datadog_tracer.rb, after Datadog.configure
    #   require 'kb/instrumentation/datadog'
    #   KB::Instrumentation::Datadog.subscribe!
    #
    # One `kb.client.request` span per call, opened when the event starts and
    # closed when it finishes, so it wraps cache lookup, TCP connect, TLS,
    # write, read and JSON parsing, and the tracer's own Net::HTTP spans nest
    # under it. No service is given, so the span inherits the app's, and it stays
    # there: the KB host is a plain `peer.hostname` tag, with no `span.kind:client`
    # or `peer.service` that would attribute it to KB. Works with
    # `ddtrace` 1.x and `datadog` 2.x; the tracer gem is the app's dependency.
    module Datadog
      OPERATION = 'kb.client.request'.freeze
      # Path segments that are identifiers, collapsed to `?` so resources stay
      # low-cardinality: `GET /v1/pets/?/contracts` rather than one per pet.
      IDENTIFIER_SEGMENT = /\A(?:\h{8}-\h{4}-\h{4}-\h{4}-\h{12}|\d+)\z/.freeze
      SPAN_KEY = :datadog_span

      class TracerMissing < StandardError; end

      class << self
        def subscribe!
          unless defined?(::Datadog::Tracing)
            raise TracerMissing, "Datadog tracing is not loaded; require 'ddtrace' or 'datadog' first"
          end

          return @subscriber if @subscriber

          @subscriber = ActiveSupport::Notifications.subscribe(KB::Client::REQUEST_EVENT, Subscriber.new)
        end

        def unsubscribe!
          ActiveSupport::Notifications.unsubscribe(@subscriber) if @subscriber
          @subscriber = nil
        end

        def subscribed?
          !@subscriber.nil?
        end

        def resource_for(base_url, verb, path)
          segments = (URI(base_url).path.split('/') + path.to_s.split('/')).reject(&:empty?)
          template = segments.map { |segment| segment.match?(IDENTIFIER_SEGMENT) ? '?' : segment }
          "#{verb.to_s.upcase} /#{template.join('/')}"
        end
      end

      class Subscriber
        def start(_name, _id, payload)
          span = ::Datadog::Tracing.trace(OPERATION, type: 'http',
                                                     resource: Datadog.resource_for(payload[:base_url], payload[:verb],
                                                                                    payload[:path]))
          # No span.kind:client / peer.service on purpose: the span covers the
          # client's whole call (cache lookup, connect, parse), so it must not be
          # inferred onto the knowledge-base service page as one of KB's operations.
          span.set_tag('peer.hostname', URI(payload[:base_url]).host)
          span.set_tag('kb.method', payload[:verb].to_s.upcase)
          payload[SPAN_KEY] = span
        end

        def finish(_name, _id, payload)
          span = payload.delete(SPAN_KEY)
          return unless span

          span.set_tag('kb.cache_hit', payload[:cache_hit].to_s) if payload.key?(:cache_hit)
          span.set_tag('http.status_code', payload[:status].to_s) if payload[:status]
          tag_transport(span, payload)
          span.set_error(payload[:exception_object]) if payload[:exception_object]
          span.finish
        end

        private

        # `kb.connections`: "new"/"reused" per attempt (keep-alive transport).
        # Only on retried calls: `kb.retries` (numeric) and the distinct underlying
        # errors that triggered them, e.g. `Net::OpenTimeout`.
        def tag_transport(span, payload)
          span.set_tag('kb.connections', payload[:connections].join(',')) if payload[:connections]
          return unless payload[:retries]

          span.set_tag('kb.retries', payload[:retries])
          span.set_tag('kb.retry_errors', payload[:retry_errors].uniq.join(','))
        end
      end
    end
  end
end
