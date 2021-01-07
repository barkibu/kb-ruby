module KB
  module Creatable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def create(attributes)
        api_response = kb_client.create(attributes)
        attributes_from_response(api_response)
      end
    end
  end
end
