module KB
  module Findable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def find(key, params = {})
        from_api(kb_client.find(key, params))
      rescue Faraday::ResourceNotFound
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
