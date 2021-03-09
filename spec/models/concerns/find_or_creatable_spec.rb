require 'spec_helper'

RSpec.describe KB::FindOrCreatable do
  subject(:find_or_create_by) do
    including_class.find_or_create_by(attributes) do |entity|
      entity.foo = 'overriden'
    end
  end

  include_context 'with KB Models Queryable Concerns'

  let(:including_class) { including_class_factory(client: :pet_parent) }
  let(:created_entity) { { key: key, foo: 'BAR', some_field: 'some other field we just ignore' } }
  let(:matching_entities) { [] }

  before do
    allow(kb_client).to receive(:create).and_return(created_entity)
    allow(kb_client).to receive(:all).and_return(matching_entities)
  end

  it 'calls `all` on the configured kb_client with given attributes' do
    find_or_create_by
    expect(kb_client).to have_received(:all).with(attributes)
  end

  context 'when no matching entity exists' do
    it 'calls `create` on the configured kb_client' do
      find_or_create_by
      expect(kb_client).to have_received(:create).with(attributes.merge(foo: 'overriden').stringify_keys)
    end
  end

  context 'when a matching entity exists' do
    let(:matching_entities) { [created_entity] }

    it 'returns the first matching element' do
      expect(find_or_create_by.foo).to eq 'BAR'
    end
  end

  context 'when the api raises an exception' do
    before do
      allow(kb_client).to receive(:create).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { find_or_create_by }.to raise_exception api_exception
    end
  end
end
