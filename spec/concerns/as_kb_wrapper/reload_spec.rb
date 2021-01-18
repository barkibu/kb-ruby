require 'spec_helper'

RSpec.describe KB::Concerns::AsKBWrapper do
  describe '#reload' do
    subject(:instance) { model_class.new(kb_key: kb_key) }

    include_context 'with a Wrapping ActiveRecord class'

    it 'forces the underlying resource stored in the local_attribute to be re-pulled on request' do
      instance.kb_model
      instance.reload
      instance.kb_model
      expect(kb_model_class).to have_received(:find).twice
    end
  end
end
