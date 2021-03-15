shared_context 'with Mock ActiveRecord Class' do
  let(:active_record_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      define_model_callbacks :save, :destroy

      attribute :kb_key, :string

      def initialize(**args)
        super
        yield self if block_given?
      end

      def reload; end

      def save
        run_callbacks :save do
          actually_acting
        end
      end

      def actually_acting
        # Active Record Magic hitting the DB
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, 'ModelClass')
      end

      def destroy
        run_callbacks :destroy do
          actually_acting
        end
      end
    end
  end
end
