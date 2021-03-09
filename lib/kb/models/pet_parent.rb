module KB
  class PetParent < BaseModel
    include Findable
    include Updatable
    include FindOrCreatable

    kb_api :pet_parent

    def self.all(filters = {})
      filters[:partner_key] = ENV['KB_PARTNER_KEY']
      super(filters)
    end

    def self.create(attributes = {})
      attributes[:partner_key] = ENV['KB_PARTNER_KEY']
      super(attributes)
    end

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key partner_key first_name last_name prefix_phone_number phone_number email].freeze
    FIELDS = [*STRING_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    alias phone_number_prefix prefix_phone_number
    alias phone_number_prefix= prefix_phone_number=

    STRING_FIELDS.each do |field|
      attribute field, :string
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

    def full_phone_number
      "#{phone_number_prefix}#{phone_number}"
    end

    def pets
      self.class.kb_client.request("#{key}/pets").map do |pet|
        Pet.from_api(pet)
      end
    end
  end
end
