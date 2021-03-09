module KB
  module Creatable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def create(attributes, &block)
        kb_entity = new(attributes.stringify_keys.slice(*attribute_names), &block)
        from_api(kb_client.create(kb_entity.attributes))
      rescue Faraday::Error => e
        raise KB::Error.new(e.response[:status], e.response[:body], e)
      end
    end
  end
end
