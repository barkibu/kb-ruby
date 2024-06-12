module KB
  module Findable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def find(key, params = {})
        from_api(kb_client.find(key, params))
      rescue Faraday::ResourceNotFound => e
        raise KB::ResourceNotFound.new(e.response[:status], e.response[:body], e)
      rescue Faraday::Error => e
        raise KB::Error.from_faraday(e)
      end
    end

    def reload
      self.class.clear_cache_for(key)
      self.attributes = self.class.find(key).attributes
      self
    end
  end
end
