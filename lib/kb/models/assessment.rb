require 'kb/types'

module KB
  class Assessment < BaseModel
    include Findable
    include Listable

    kb_api :consultation

    class << self
      def by_pet(pet)
        all(user: pet.kb_key)
      end

      private

      def attributes_from_response(response)
        response.transform_keys(&:underscore).transform_keys(&:to_sym).slice(*FIELDS)
      end
    end

    # Legacy Field Name From Anamnesis
    alias_attribute :consultation_id, :key
    alias_attribute :should_stop, :finished
    alias_attribute :created_at, :date

    attribute :invalid_symptoms, default: [] # Deprecated ?
    attribute :conditions, :array_of_conditions
    attribute :symptoms, :array_of_symptoms

    attribute :date, :date
    attribute :finished, :boolean, default: false

    attribute :urgency, :string
    attribute :key, :string
    attribute :pet_key, :string

    STRING_FIELDS = %i[key pet_key urgency].freeze
    FIELDS = [*STRING_FIELDS, :date, :should_stop, :finished, :conditions, :symptoms, :next_question].freeze

    def urgent
      return false if urgency == 'low'

      true
    end
  end
end
