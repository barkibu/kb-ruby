require 'spec_helper'

RSpec.describe KB::Findable do
  include_context 'KB Models Queryable Concerns'

  subject(:find) { including_class.find(key) }

  let(:including_class) { including_class_factory(client: :consultation) }
  let(:found_entity) { { key: key, foo: 'bar', some_field: 'a field we just ignore' } }

  it 'calls `find` on the configured client' do
    expect(kb_client).to receive(:find).with(key).and_return(found_entity)
    find
  end

  context 'if the api call succeeds' do
    before do
      allow(kb_client).to receive(:find).and_return(found_entity)
    end

    it 'calls `attributes_from_response` on the including class' do
      expect(including_class).to receive(:attributes_from_response).with(found_entity)
      find
    end

    it 'calls new on the including class with the result of `attributes_from_response` ' do
      expect(including_class).to receive(:new).with(including_class.attributes_from_response(found_entity))
      find
    end

    it 'returns an instance of the including class' do
      expect(find.instance_of?(including_class)).to be(true)
    end
  end

  context 'if the api raises an exception' do
    before do
      allow(kb_client).to receive(:find).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { find }.to raise_exception api_exception
    end

    context 'if the exception is Faraday::ResourceNotFound' do
      let(:api_exception) { Faraday::ResourceNotFound.new 'Ooops' }

      it 'raises an ActiveRecord::RecordNotFound exception' do
        expect { find }.to raise_exception ActiveRecord::RecordNotFound
      end
    end
  end
end
