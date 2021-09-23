module KB
  module Destroyable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def destroy(key)
        kb_client.destroy(key)
      rescue Faraday::Error => e
        raise KB::Error.from_faraday(e)
      end
    end
  end
end
