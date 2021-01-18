require 'spec_helper'

RSpec.describe KB::Listable do
  subject(:list) { including_class.all(filters) }

  include_context 'with KB Models Queryable Concerns'

  let(:including_class) { including_class_factory(client: :pet_parent) }
  let(:filters) { { foo: 'bar' } }
  let(:found_entities) { [{ key: 'key1', foo: 'bar', some_field: 'a field we just ignore' }] }

  before do
    allow(kb_client).to receive(:all).and_return(found_entities)
    allow(including_class).to receive(:new).and_call_original
  end

  it 'calls `all` on the configured kb_client' do
    list
    expect(kb_client).to have_received(:all).with(filters)
  end

  context 'when the api call succeeds' do
    it 'calls `attributes_from_response` on the including class' do
      list
      found_entities.each do |found_entity|
        expect(including_class).to have_received(:attributes_from_response).with(found_entity)
      end
    end

    it 'calls new on the including class with the result of `attributes_from_response` ' do
      list
      found_entities.each do |found_entity|
        expect(including_class).to have_received(:new).with(including_class.attributes_from_response(found_entity))
      end
    end

    it 'returns an instance of the including class' do
      expect(list).to all(be_an_instance_of(including_class))
    end
  end

  context 'when the api raises an exception' do
    before do
      allow(kb_client).to receive(:all).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { list }.to raise_exception api_exception
    end
  end
end
