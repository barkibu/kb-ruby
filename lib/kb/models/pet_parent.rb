module KB
  class PetParent < BaseModel
    include Findable
    include Updatable
    include FindOrCreatable
    include Upsertable
    include Destroyable

    kb_api :pet_parent

    def self.all(filters = {})
      filters[:partner_key] = ENV['KB_PARTNER_KEY']
      super(filters)
    end

    def self.create(attributes = {})
      attributes[:partner_key] = ENV['KB_PARTNER_KEY']
      super(attributes)
    end

    def self.upsert(attributes)
      attributes[:partner_key] = ENV['KB_PARTNER_KEY']
      super(attributes)
    end

    def merge!(duplicated_pet_parent_key)
      params = { preservable_pet_parent_key: key,
                 erasable_pet_parent_key: duplicated_pet_parent_key }.transform_keys do |key|
        key.to_s.camelize(:lower)
      end

      response = KB::ClientResolver.admin.request("petparents?#{params.to_query}", method: :put)
      PetParent.from_api response
    rescue Faraday::Error => e
      raise KB::Error.from_faraday(e)
    end

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key partner_name first_name last_name prefix_phone_number phone_number email country address
                       zip_code nif affiliate_code city iban_last4].freeze
    DATE_FIELDS = %i[birth_date deleted_at].freeze
    BOOLEAN_FIELDS = %i[phone_number_verified email_verified].freeze
    FIELDS = [*STRING_FIELDS, *DATE_FIELDS, *BOOLEAN_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    alias phone_number_prefix prefix_phone_number
    alias phone_number_prefix= prefix_phone_number=

    define_attributes STRING_FIELDS, :string
    define_attributes DATE_FIELDS, :date
    define_attributes BOOLEAN_FIELDS, :boolean
    attribute :first_name, :string, default: ''

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

    def destroyed?
      @destroyed
    end

    def destroy!
      return unless @persisted

      self.class.destroy key
      @destroyed = true
      freeze
    end

    def full_phone_number
      "#{phone_number_prefix}#{phone_number}"
    end

    def pets
      self.class.kb_client.request("#{key}/pets").map do |pet|
        Pet.from_api(pet)
      end
    end

    def contracts
      self.class.kb_client.request("#{key}/contracts").map do |contract|
        PetContract.from_api(contract)
      end
    end

    def referrals
      self.class.kb_client.request("#{key}/referrals").map do |referral|
        Referral.from_api(referral)
      end
    end

    def referrers
      self.class.kb_client.request("#{key}/referrers").map do |referral|
        Referral.from_api(referral)
      end
    end

    def iban
      @iban ||= self.class.kb_client.request("#{key}/iban")['iban']
    rescue Faraday::Error => e
      raise KB::Error.from_faraday(e)
    end

    def update_iban(iban)
      self.class.kb_client.request("#{key}/iban", filters: { iban: iban }, method: :put)
      reload
    rescue Faraday::Error => e
      raise KB::Error.from_faraday(e)
    end
  end
end
