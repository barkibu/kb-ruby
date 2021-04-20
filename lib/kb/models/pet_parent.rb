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

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key partner_key first_name last_name prefix_phone_number phone_number email].freeze
    DATE_FIELDS = %i[deleted_at].freeze
    FIELDS = [*STRING_FIELDS, *DATE_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    alias phone_number_prefix prefix_phone_number
    alias phone_number_prefix= prefix_phone_number=

    STRING_FIELDS.each do |field|
      attribute field, :string
    end

    DATE_FIELDS.each do |field|
      attribute field, :date
    end

    attribute :first_name, :string, default: ''

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
