module KB
  class Pet < BaseModel
    include Findable
    include Updatable
    include FindOrCreatable

    kb_api :pet

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key pet_parent_key name age_category sex breed chip species].freeze
    BOOLEAN_FIELDS = %i[neutered mongrel].freeze
    FIELDS = [*STRING_FIELDS, *BOOLEAN_FIELDS, :birth_date].freeze

    define_attribute_methods(*FIELDS)

    STRING_FIELDS.each do |field|
      attribute field, :string
    end

    BOOLEAN_FIELDS.each do |field|
      attribute field, :boolean
    end

    attribute :birth_date, :date

    FIELDS.each do |field|
      define_method :"#{field}=" do |value|
        public_send "#{field}_will_change!"
        super(value)
      end
    end

    def save!
      return unless changed?

      run_callbacks :save do
        self.attributes = if @persisted
                            self.class.update key, changes.transform_values(&:last)
                          else
                            self.class.create changes.transform_values(&:last)
                          end

        self
      end
    end
  end
end
