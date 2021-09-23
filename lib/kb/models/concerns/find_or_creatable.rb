module KB
  module FindOrCreatable
    extend ActiveSupport::Concern

    included do
      include Queryable
      include Listable
      include Creatable
    end

    module ClassMethods
      def find_or_create_by(attributes, additional_attributes)
        all(attributes).first || new(create(additional_attributes.merge(attributes)), &:persist!)
      rescue Faraday::Error => e
        raise KB::Error.from_faraday(e)
      end
    end
  end
end
