module KB
  class Breed < BaseModel
    include Listable

    DEFAULT_LOCALE = ENV.fetch('KB_BREEDS_DEFAULT_LOCALE', 'es-es')

    kb_api :breed

    def self.all(filters = {})
      filters[:locale] ||= DEFAULT_LOCALE
      super(filters)
    end

    def self.dogs(filters = {})
      filters[:species] = 'dog'
      all(filters)
    end

    def self.cats(filters = {})
      filters[:species] = 'cat'
      all(filters)
    end

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key locale name species weight_group external_id].freeze
    FIELDS = [*STRING_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    define_attributes STRING_FIELDS, :string
  end
end
