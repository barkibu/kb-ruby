require 'spec_helper'

RSpec.describe KB::Searchable do
  subject(:search) { including_class.search(filters) }

  include_context 'with KB Models Queryable Concerns'

  let(:including_class) { including_class_factory(client: :pet_parent) }
  let(:filters) { { foo: 'bar' } }
  let(:found_entities) { [{ key: 'key1', foo: 'bar', some_field: 'a field we just ignore' }] }
  let(:response) { { 'total' => 1, 'page' => 0, 'elements' => found_entities } }

  before do
    allow(kb_client).to receive(:request).and_return(response)
    allow(including_class).to receive(:from_api).and_call_original
  end

  it 'makes a request to `search` with filters on the configured kb_client' do
    search
    expect(kb_client).to have_received(:request).with('search', filters: filters)
  end

  context 'when the api call succeeds' do
    it 'calls `from_api` on the including class' do
      search
      found_entities.each do |found_entity|
        expect(including_class).to have_received(:from_api).with(found_entity)
      end
    end

    it 'returns a KB::SearchResult object' do
      expect(search).to be_a(KB::SearchResult)
    end

    it 'returns instances of the including class' do
      expect(search.elements).to all(be_an_instance_of(including_class))
    end
  end

  context 'when the api raises an exception' do
    before do
      allow(kb_client).to receive(:request).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { search }.to raise_exception api_exception
    end
  end
end
