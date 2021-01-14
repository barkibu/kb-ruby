require 'spec_helper'

# rubocop:disable RSpec/SubjectStub
RSpec.describe KB::Concerns::AsKBWrapper do
  describe '#save_underlying_kb_entity!' do
    subject(:instance) { model_class.new(kb_key: kb_key) }

    include_context 'with a Wrapping ActiveRecord class'

    before do
      allow(instance).to receive(:kb_key=).and_call_original # Setting a spy
      allow(instance).to receive(:save_underlying_kb_entity!).and_call_original # Setting a spy
      allow(instance).to receive(:actually_saving).and_call_original # Setting a spy
    end

    it 'calls `save` on the underlying kb resource' do
      instance.save_underlying_kb_entity!
      expect(kb_model_instance).to have_received(:save!)
    end

    it 'sets the received kb resource key on the `kb_key` attribute' do
      instance.save_underlying_kb_entity!
      expect(instance).to have_received('kb_key=').with(kb_key)
    end

    it 'calls :save_underlying_kb_entity! before actually saving the record' do # rubocop:disable RSpec/MultipleExpectations
      instance.save
      expect(instance).to have_received(:save_underlying_kb_entity!).ordered
      expect(instance).to have_received(:actually_saving).ordered
    end

    context 'with `skip_callback` option' do
      let(:skip_callback) { true }

      it 'calls :save_underlying_kb_entity! before actually saving the record' do # rubocop:disable RSpec/MultipleExpectations
        instance.save
        expect(instance).not_to have_received(:save_underlying_kb_entity!)
        expect(instance).to have_received(:actually_saving)
      end
    end
  end
end
# rubocop:enable RSpec/SubjectStub
