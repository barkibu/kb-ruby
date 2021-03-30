module KB
  class Condition
    include Inspectionable
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Serializers::JSON

    FIELDS = %i[key name score usualness urgent information urgency].freeze

    attribute :key, :string
    attribute :name, :string
    attribute :score, :float
    attribute :usualness, :integer
    attribute :urgency, :string

    attribute :article, :string, default: ''
    attribute :description_short, :string
    attribute :diagnosis, :string
    attribute :treatment, :string
    attribute :prevention, :string
    attribute :first_aid, :string
    attribute :predisposition_factors, :string

    alias_attribute :information, :article

    def urgent
      return false if urgency == 'low'

      true
    end
  end
end
