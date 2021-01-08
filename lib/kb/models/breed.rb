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

    STRING_FIELDS = %i[key breed_parent_key weight_group species].freeze
    INTEGER_FIELDS = %i[risk].freeze
    DECIMAL_FIELDS = %i[weight_min weight_max lifespan].freeze
    ARRAY_FIELDS = %i[names].freeze
    FIELDS = [*STRING_FIELDS, *INTEGER_FIELDS, *DECIMAL_FIELDS, *ARRAY_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    STRING_FIELDS.each do |field|
      attribute field, :string
    end

    INTEGER_FIELDS.each do |field|
      attribute field, :integer
    end

    DECIMAL_FIELDS.each do |field|
      attribute field, :decimal
    end

    ARRAY_FIELDS.each do |field|
      attribute field, :array_of_strings, default: []
    end

    FIELDS.each do |field|
      define_method :"#{field}=" do |value|
        public_send "#{field}_will_change!"
        super(value)
      end
    end
  end
end
