shared_context 'with Mock ActiveRecord Class' do
  let(:active_record_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      define_model_callbacks :save

      attribute :kb_key, :string

      def initialize(**args)
        super
        yield self if block_given?
      end

      def reload; end

      def save
        run_callbacks :save do
          actually_saving
        end
      end

      def actually_saving
        # Active Record Magic saving stuff to the DB
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, 'ModelClass')
      end
    end
  end
end
