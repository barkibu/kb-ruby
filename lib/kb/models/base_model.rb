module KB
  class BaseModel
    include Inspectionable
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Serializers::JSON
    include ActiveModel::Dirty

    attr_accessor :persisted

    define_model_callbacks :save
    after_save :persist!

    def initialize(attributes = {})
      super
      @persisted = false
      yield self if block_given?
    end

    def persisted?
      @persisted
    end

    def persist!
      changes_applied
      @persisted = true
    end
  end
end
