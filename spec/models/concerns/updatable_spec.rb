require 'spec_helper'

RSpec.describe KB::Updatable do
  include_context 'KB Models Queryable Concerns'

  subject(:update) { including_class.update(key, attributes) }

  let(:including_class) { including_class_factory(client: :pet_parent) }
  let(:updated_entity) { { key: key, foo: 'bar', some_field: 'a field we just ignore' } }

  it 'calls `update` on the configured kb_client' do
    expect(kb_client).to receive(:update).with(key, attributes).and_return(updated_entity)
    update
  end

  context 'if the api accepts the update' do
    before do
      allow(kb_client).to receive(:update).and_return(updated_entity)
    end

    it 'calls `attributes_from_response` on the including class' do
      expect(including_class).to receive(:attributes_from_response).with(updated_entity)
      update
    end

    it 'returns the result of `attributes_from_response`' do
      expect(update).to eq(including_class.attributes_from_response(updated_entity))
    end
  end

  context 'if the api raises an exception' do
    before do
      allow(kb_client).to receive(:update).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { update }.to raise_exception api_exception
    end
  end
end
