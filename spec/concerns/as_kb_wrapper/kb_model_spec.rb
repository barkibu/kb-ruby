require 'spec_helper'

RSpec.describe KB::Concerns::AsKBWrapper do
  describe '#kb_model' do
    subject(:instance) { model_class.new(kb_key: kb_key) }

    include_context 'with a Wrapping ActiveRecord class'

    it 'allow kb_model to be set' do
      instance.kb_model = kb_model_new_instance
      expect(instance.kb_model).to be kb_model_new_instance
    end

    it 'calls `find` on the underlying kb entity class' do
      instance.kb_model
      expect(kb_model_class).to have_received :find
    end

    it 'serves the cached first fetched underlying kb entity on subsequent requests' do
      instance.kb_model
      instance.kb_model
      expect(kb_model_class).to have_received(:find).once
    end

    it 'returns the KB resource found' do
      expect(instance.kb_model).to be kb_model_instance
    end

    context 'when the KB resource is not found' do
      before do
        allow(kb_model_class).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it 'returns a fresh KB resource if not found' do
        expect(instance.kb_model).to be kb_model_new_instance
      end
    end
  end
end
