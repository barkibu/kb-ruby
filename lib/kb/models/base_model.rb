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

    class << self
      delegate :clear_cache_for, to: :kb_client

      def define_attribute_methods(*fields)
        super
        fields.each do |field|
          define_method :"#{field}=" do |value|
            super(value).tap do
              public_send "#{field}_will_change!" if public_send("#{field}_changed?")
            end
          end
        end
      end
    end

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

    # Copy-paste of ActiveRecord equality logic
    # https://github.com/rails/rails/blob/main/activerecord/lib/active_record/core.rb
    def ==(other)
      super ||
        (other.instance_of?(self.class) &&
        !key.nil? &&
        other.key == key)
    end
    alias eql? ==
  end
end
