require 'spec_helper'

RSpec.describe KB::Findable do
  subject(:find) { including_class.find(key) }

  include_context 'with KB Models Queryable Concerns'

  let(:including_class) { including_class_factory(client: :consultation) }
  let(:found_entity) { { key: key, foo: 'bar', some_field: 'a field we just ignore' } }

  before do
    allow(kb_client).to receive(:find).and_return(found_entity)
    allow(including_class).to receive(:new).and_call_original
  end

  it 'calls `find` on the configured client' do
    find
    expect(kb_client).to have_received(:find).with(key)
  end

  context 'when the api call succeeds' do
    it 'calls `attributes_from_response` on the including class' do
      find
      expect(including_class).to have_received(:attributes_from_response).with(found_entity)
    end

    it 'calls new on the including class with the result of `attributes_from_response` ' do
      find
      expect(including_class).to have_received(:new).with(including_class.attributes_from_response(found_entity))
    end

    it 'returns an instance of the including class' do
      expect(find).to be_an_instance_of(including_class)
    end
  end

  context 'when the api raises an exception' do
    before do
      allow(kb_client).to receive(:find).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { find }.to raise_exception api_exception
    end

    context 'when the exception is Faraday::ResourceNotFound' do
      let(:api_exception) { Faraday::ResourceNotFound.new 'Ooops' }

      it 'raises an ActiveRecord::RecordNotFound exception' do
        expect { find }.to raise_exception ActiveRecord::RecordNotFound
      end
    end
  end
end
