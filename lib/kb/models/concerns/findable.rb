module KB
  module Findable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def find(key)
        from_api(kb_client.find(key))
      rescue Faraday::ResourceNotFound
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
