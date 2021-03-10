module KB
  module FindOrCreatable
    extend ActiveSupport::Concern

    included do
      include Queryable
      include Listable
      include Creatable
    end

    module ClassMethods
      def find_or_create_by(attributes, &block)
        all(attributes).first || create(attributes, &block)
      rescue Faraday::Error => e
        raise KB::Error.new(e.response[:status], e.response[:body], e)
      end
    end
  end
end
