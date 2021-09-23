module KB
  module Listable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def all(filters = {})
        kb_client.all(filters).map do |pet_parent|
          from_api pet_parent
        end
      rescue Faraday::ConnectionFailed => e
        raise e
      rescue Faraday::Error => e
        raise KB::Error.from_faraday(e)
      end
    end
  end
end
