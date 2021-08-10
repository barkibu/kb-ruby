module KB
  class PetContract < BaseModel
    include Findable
    include Creatable
    include Updatable

    kb_api :pet_contract

    def self.find_by_contract_number(contract_number)
      find("contractnumber/#{contract_number}")
    end

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key plan_key pet_key contract_number contract_document status
                       source affiliate_online affiliate_offline].freeze
    DATE_FIELDS = %i[policy_start_date policy_expiration_date].freeze
    INTEGER_FIELDS = %i[price_yearly price_monthly].freeze
    FIELDS = [*STRING_FIELDS, *DATE_FIELDS, *INTEGER_FIELDS].freeze

    IMMUTABLE_FIELDS = (FIELDS - %i[status contract_document policy_expiration_date]).freeze

    define_attribute_methods(*FIELDS)

    STRING_FIELDS.each do |field|
      attribute field, :string
    end

    DATE_FIELDS.each do |field|
      attribute field, :date
    end

    INTEGER_FIELDS.each do |field|
      attribute field, :integer
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

    def plan
      @plan ||= Plan.all.select { |plan| plan.key == plan_key }
    end

    def pet
      @pet ||= Pet.find(pet_key)
    end
  end
end
