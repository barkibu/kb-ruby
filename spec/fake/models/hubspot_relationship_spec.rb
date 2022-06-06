require 'spec_helper'
require 'kb-fake'

RSpec.describe KB::HubspotRelationship do
  around do |example|
    snapshot = KB::Fake::Api.snapshot()
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::Api)
    example.run
    KB::Fake::Api.restore snapshot
  end

  after { described_class.send(:remove_instance_variable, :@kb_client) }

  describe '#find' do
    subject(:find) { described_class.find(model, model_key) }

    let(:model) { :pet_contract }
    let(:model_key) { SecureRandom.uuid }

    context 'with no existing relationship' do
      it 'raises a ResourceNotFound' do
        expect { find }.to raise_exception(KB::ResourceNotFound)
      end
    end

    context 'with an existing relationship' do
      before do
        KB::Fake::Api.restore(hubspot_relationship: [{ key: model_key, model: model,
                                                       hubspot_id: existing_hubspot_id }.with_indifferent_access])
      end

      let(:existing_hubspot_id) { '123456' }

      it 'returns the existing relationship' do
        expect(find.hubspot_id).to eq(existing_hubspot_id)
      end
    end
  end
end
