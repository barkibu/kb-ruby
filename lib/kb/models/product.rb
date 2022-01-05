module KB
  class Product < BaseModel
    include Listable
    include Findable

    kb_api :product

    def self.by_country(country)
      all(country: country)
    end

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key country name type].freeze
    STRING_ARRAY_FIELDS = %i[exclusions inclusions features claimable_by languages].freeze
    FIELDS = [*STRING_FIELDS, *STRING_ARRAY_FIELDS, :purchasable].freeze

    define_attribute_methods(*FIELDS)

    attribute :purchasable, :boolean

    STRING_FIELDS.each do |field|
      attribute field, :string
    end

    STRING_ARRAY_FIELDS.each do |field|
      attribute field, :array_of_strings
    end
  end
end
