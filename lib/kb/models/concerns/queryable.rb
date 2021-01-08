module KB
  module Queryable
    class KBClientNotSetException < StandardError; end
    extend ActiveSupport::Concern

    included do
      class_attribute :resolver_factory
    end

    module ClassMethods
      private

      def kb_api(resolver_factory)
        self.resolver_factory = resolver_factory
      end

      def kb_client
        raise KBClientNotSetException, "You probably forgot to call `kb_api ...` on the class #{name}" if resolver_factory.blank?

        @kb_client ||= ClientResolver.public_send(resolver_factory)
      end

      # @abstract Subclass is expected to implement #attributes_from_response
      # @!method attributes_from_response
      #    Filter and process the response to return the relevant attributes for entity initialization
    end
  end
end
