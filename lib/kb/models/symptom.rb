module KB
  class Symptom
    # include TranslationOverridable
    include Inspectionable
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Serializers::JSON

    attribute :key, :string
    attribute :name, :string
    attribute :presence, :string
    attribute :duration, :string
    attribute :frequency, :string

    attribute :urgency, :string
    attribute :article, :string, default: ''

    # translatable_attributes :name, :article

    alias_attribute :information, :article
    # translatable_attributes :information

    def urgent
      return false if urgency == 'low'

      true
    end
  end
end
