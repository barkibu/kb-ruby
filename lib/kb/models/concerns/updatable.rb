module KB
  module Updatable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def update(key, attributes)
        api_response = kb_client.update(key, attributes)
        attributes_from_response(api_response)
      rescue Faraday::Error => e
        raise KB::Error.new(e.response[:status], e.response[:body], e)
      end
    end
  end
end
