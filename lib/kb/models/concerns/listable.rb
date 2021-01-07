module KB
  module Listable
    extend ActiveSupport::Concern

    included do
      include Queryable
    end

    module ClassMethods
      def all(filters = {})
        kb_client.all(filters).map do |pet_parent|
          new attributes_from_response(pet_parent), &:persist!
        end
      rescue Faraday::Error => e
        KB::Error.new(e.response[:status], e.response[:body])
      end
    end
  end
end
