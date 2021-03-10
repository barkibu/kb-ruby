require 'spec_helper'

RSpec.describe KB::Creatable do
  subject(:create) { including_class.create(attributes) }

  include_context 'with KB Models Queryable Concerns'

  let(:including_class) { including_class_factory(client: :pet_parent) }
  let(:created_entity) { { key: key, foo: 'bar', some_field: 'some other field we just ignore' } }

  before do
    allow(kb_client).to receive(:create).and_return(created_entity)
  end

  it 'calls `create` on the configured kb_client' do
    create
    expect(kb_client).to have_received(:create).with(attributes.with_indifferent_access)
  end

  context 'when the api accepts the CREATE' do
    it 'calls `attributes_from_response` on the including class' do
      create
      expect(including_class).to have_received(:attributes_from_response).with(created_entity)
    end

    it 'returns an instance of the including class' do
      expect(create).to be_a(including_class)
    end
  end

  context 'when the api raises an exception' do
    before do
      allow(kb_client).to receive(:create).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { create }.to raise_exception api_exception
    end
  end
end
