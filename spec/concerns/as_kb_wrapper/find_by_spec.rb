require 'spec_helper'

RSpec.describe KB::Concerns::AsKBWrapper do
  include_context 'with a Wrapping ActiveRecord class'
  let(:params) { { foo: 'bar' } }
  let(:instance) { model_class.new(kb_key: kb_key) }

  describe '#kb_find_by' do
    subject(:kb_find_by) { model_class.kb_find_by(**params) }

    before do
      allow(kb_model_class).to receive(:all).and_return [kb_model_instance]
      allow(model_class).to receive(:find_by).with(kb_key: kb_key).and_return instance
    end

    it 'returns nil if no record matches in API' do
      allow(kb_model_class).to receive(:all).and_return []
      expect(kb_find_by).to be_nil
    end

    it 'returns nil if no wrapping record matches the one in API' do
      allow(model_class).to receive(:find_by).with(kb_key: kb_key).and_return nil
      expect(kb_find_by).to be_nil
    end

    it 'calls `all` on the underlying kb class' do
      kb_find_by
      expect(kb_model_class).to have_received(:all).with(params)
    end

    it 'returns the wrapping model identified by the key of the underlying KB class' do
      expect(kb_find_by).to eq instance
    end

    it 'sets the kb_model on the returned instance' do
      expect(kb_find_by.kb_model).to eq kb_model_instance
    end
  end

  describe '#kb_find_by!' do
    subject(:kb_find_by!) { model_class.kb_find_by!(**params) }

    before do
      allow(model_class).to receive(:kb_find_by).with(params).and_return(instance) # Setting a spy
    end

    it 'returns whatever non nil kb_find_by returns' do
      expect(kb_find_by!).to eq instance
    end

    context 'when no records match' do
      before do
        allow(model_class).to receive(:kb_find_by).with(params).and_return nil
      end

      it 'raise an ActiveRecord::RecordNotFound  when kb_find_by returns nil' do
        expect { kb_find_by! }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end
end
