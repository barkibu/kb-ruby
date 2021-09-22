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
      rescue Faraday::Error => error
        raise KB::Error.from_faraday(error)
      end
    end
  end
end
