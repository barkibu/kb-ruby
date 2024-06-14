module KB
  class Pet < BaseModel
    include Findable
    include Updatable
    include FindOrCreatable
    include Destroyable
    include Upsertable

    kb_api :pet

    def self.attributes_from_response(response)
      response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
    end

    private_class_method :attributes_from_response

    STRING_FIELDS = %i[key pet_parent_key name age_category sex breed chip species].freeze
    DATE_FIELDS = %i[birth_date deleted_at].freeze
    BOOLEAN_FIELDS = %i[neutered mongrel].freeze
    FIELDS = [*STRING_FIELDS, *DATE_FIELDS, *BOOLEAN_FIELDS].freeze

    define_attribute_methods(*FIELDS)

    define_attributes STRING_FIELDS, :string
    define_attributes DATE_FIELDS, :date
    define_attributes BOOLEAN_FIELDS, :boolean

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

    def contracts
      self.class.kb_client.request("#{key}/contracts").map do |contract|
        PetContract.from_api(contract)
      end
    end
  end
end
