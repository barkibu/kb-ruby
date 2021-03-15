require 'spec_helper'

RSpec.describe KB::Destroyable do
  subject(:destroy) { including_class.destroy(key) }

  include_context 'with KB Models Queryable Concerns'

  let(:including_class) { including_class_factory(client: :pet_parent) }

  before do
    allow(kb_client).to receive(:destroy).and_return(nil)
  end

  it 'calls `destroy` on the configured kb_client' do
    destroy
    expect(kb_client).to have_received(:destroy).with(key)
  end

  context 'when the api accepts the destroy' do
    it 'returns nil' do
      expect(destroy).to eq(nil)
    end
  end

  context 'when the api raises an exception' do
    before do
      allow(kb_client).to receive(:destroy).and_raise(api_exception)
    end

    it 'raises this exception' do
      expect { destroy }.to raise_exception api_exception
    end
  end
end
