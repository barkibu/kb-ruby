require 'spec_helper'

RSpec.describe KB::Updatable do
  subject(:update) { including_class.update(key, attributes) }

  include_context 'with KB Models Queryable Concerns'

  let(:including_class) { including_class_factory(client: :pet_parent) }
  let(:updated_entity) { { key: key, foo: 'bar', some_field: 'a field we just ignore' } }

  before do
    allow(kb_client).to receive(:update).and_return(updated_entity)
  end

  it 'calls `update` on the configured kb_client' do
    update
    expect(kb_client).to have_received(:update).with(key, attributes)
  end

  context 'when the api accepts the update' do
    it 'calls `attributes_from_response` on the including class' do
      update
      expect(including_class).to have_received(:attributes_from_response).with(updated_entity)
    end

    it 'returns the result of `attributes_from_response`' do
      expect(update).to eq(including_class.attributes_from_response(updated_entity))
    end
  end

  context 'when the api raises an exception' do
    before do
      allow(kb_client).to receive(:update).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { update }.to raise_exception api_exception
    end
  end
end
