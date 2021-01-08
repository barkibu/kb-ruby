require 'spec_helper'

RSpec.describe KB::Listable do
  include_context 'KB Models Queryable Concerns'

  subject(:all) { including_class.all(filters) }

  let(:including_class) { including_class_factory(client: :pet_parent) }
  let(:filters) { { foo: 'bar' } }
  let(:found_entities) { [{ key: 'key1', foo: 'bar', some_field: 'a field we just ignore' }] }

  it 'calls `all` on the configured kb_client' do
    expect(kb_client).to receive(:all).with(filters).and_return(found_entities)
    all
  end

  context 'if the api call succeeds' do
    before do
      allow(kb_client).to receive(:all).and_return(found_entities)
    end

    it 'calls `attributes_from_response` on the including class' do
      found_entities.each do |found_entity|
        expect(including_class).to receive(:attributes_from_response).with(found_entity)
      end
      all
    end

    it 'calls new on the including class with the result of `attributes_from_response` ' do
      found_entities.each do |found_entity|
        expect(including_class).to receive(:new).with(including_class.attributes_from_response(found_entity))
      end
      all
    end

    it 'returns an instance of the including class' do
      all.each do |entity|
        expect(entity.instance_of?(including_class)).to be(true)
      end
    end
  end

  context 'if the api raises an exception' do
    before do
      allow(kb_client).to receive(:all).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { all }.to raise_exception api_exception
    end
  end
end
