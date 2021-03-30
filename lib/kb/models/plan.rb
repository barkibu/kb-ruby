module KB
  class Plan < BaseModel
    include Listable

    kb_api :plan

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key description name type].freeze
    HASH_FIELDS = %i[benefits price].freeze
    FIELDS = [*STRING_FIELDS, *HASH_FIELDS, :plan_life, :purchasable].freeze

    define_attribute_methods(*FIELDS)

    attribute :plan_life, :integer
    attribute :purchasable, :boolean

    STRING_FIELDS.each do |field|
      attribute field, :string
    end

    HASH_FIELDS.each do |field|
      attribute field
    end

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
