shared_context 'with a Wrapping ActiveRecord class' do # rubocop:disable RSpec/MultipleMemoizedHelpers
  include_context 'with Mock ActiveRecord Class'

  let(:kb_model_class) { class_double KB::Pet, find: kb_model_instance, new: kb_model_new_instance }
  let(:kb_model_instance) { instance_double KB::Pet, save!: self, key: kb_key }
  let(:kb_model_new_instance) { instance_double KB::Pet, save!: self, key: kb_key }
  let(:kb_key) { 'Underlying KB Resource Key' }
  let(:skip_callback) { false }

  let(:model_class) do
    resource_class = kb_model_class
    wrapper_skip_callback = skip_callback
    Class.new(active_record_class) do
      include KB::Concerns::AsKBWrapper
      wrap_kb model: resource_class, skip_callback: wrapper_skip_callback

      def self.find_by(*)
        raise NotImplementedError, 'stub the return value in your spec'
      end
    end
  end
end
