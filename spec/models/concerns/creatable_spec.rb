require 'spec_helper'

RSpec.describe KB::Creatable do
  include_context 'KB Models Queryable Concerns'

  subject(:create) { including_class.create(attributes) }

  let(:including_class) { including_class_factory(client: :pet_parent) }
  let(:created_entity) { { key: key, foo: 'bar', some_field: 'some other field we just ignore' } }

  it 'calls `create` on the configured kb_client' do
    expect(kb_client).to receive(:create).with(attributes).and_return(created_entity)
    create
  end

  context 'if the api accepts the CREATE' do
    before do
      allow(kb_client).to receive(:create).and_return(created_entity)
    end

    it 'calls `attributes_from_response` on the including class' do
      expect(including_class).to receive(:attributes_from_response).with(created_entity)
      create
    end

    it 'returns the result of `attributes_from_response`' do
      expect(create).to eq(including_class.attributes_from_response(created_entity))
    end
  end

  context 'if the api raises an exception' do
    before do
      allow(kb_client).to receive(:create).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { create }.to raise_exception api_exception
    end
  end
end
