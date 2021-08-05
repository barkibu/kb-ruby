module KB
  class Plan < BaseModel
    include Listable

    kb_api :plan

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key description plan_name type].freeze
    HASH_FIELDS = %i[benefits price].freeze
    FIELDS = [*STRING_FIELDS, *HASH_FIELDS, :plan_life_in_months, :buyable].freeze

    define_attribute_methods(*FIELDS)

    attribute :plan_life_in_months, :integer
    attribute :buyable, :boolean

    STRING_FIELDS.each do |field|
      attribute field, :string
    end

    HASH_FIELDS.each do |field|
      attribute field
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
