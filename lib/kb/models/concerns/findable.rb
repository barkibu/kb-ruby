module KB
  module Findable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def find(key)
        api_response = kb_client.find(key)
        new attributes_from_response(api_response), &:persist!
      rescue Faraday::ResourceNotFound
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
