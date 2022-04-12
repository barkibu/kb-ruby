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
      from_api response
    end

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key partner_name first_name last_name prefix_phone_number
                       phone_number email country address zip_code nif affiliate_code].freeze
    DATE_FIELDS = %i[birth_date deleted_at].freeze
    BOOLEAN_FIELDS = %i[phone_number_verified email_verified].freeze
    FIELDS = [*STRING_FIELDS, *DATE_FIELDS, *BOOLEAN_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    alias phone_number_prefix prefix_phone_number
    alias phone_number_prefix= prefix_phone_number=

    STRING_FIELDS.each do |field|
      attribute field, :string
    end

    DATE_FIELDS.each do |field|
      attribute field, :date
    end

    BOOLEAN_FIELDS.each do |field|
      attribute field, :boolean
    end

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
  end
end
