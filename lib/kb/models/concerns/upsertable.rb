module KB
  module Upsertable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def upsert(attributes)
        from_api kb_client.upsert(attributes)
      rescue Faraday::Error => error
        raise KB::Error.from_faraday(error)
      end
    end
  end
end
