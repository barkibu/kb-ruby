module KB
  module Destroyable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def destroy(key)
        kb_client.destroy(key)
      rescue Faraday::Error => error
        raise KB::Error.from_faraday(error)
      end
    end
  end
end
