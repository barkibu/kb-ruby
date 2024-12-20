module KB
  class PetContract < BaseModel
    include Findable
    include Creatable
    include Updatable
    include Searchable

    kb_api :pet_contract

    def self.find_by_contract_number(contract_number)
      find("contractnumber/#{contract_number}")
    end

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key plan_key product_key pet_key contract_number contract_document status
                       source affiliate_online affiliate_offline
                       conversion_utm_adgroup conversion_utm_campaign
                       conversion_utm_content conversion_utm_medium
                       conversion_utm_source conversion_utm_term
                       conversion_utm_adgroup_id conversion_utm_campaign_id].freeze
    DATE_FIELDS = %i[policy_start_date policy_expiration_date].freeze
    INTEGER_FIELDS = %i[
      price_yearly price_monthly price_discount_yearly payment_interval_months
    ].freeze
    FIELDS = [*STRING_FIELDS, *DATE_FIELDS, *INTEGER_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    define_attributes STRING_FIELDS, :string
    define_attributes DATE_FIELDS, :date
    define_attributes INTEGER_FIELDS, :integer

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

    def product
      @product ||= Product.find product_key
    end

    def pet
      @pet ||= Pet.find(pet_key)
    end
  end
end
