require 'spec_helper'

RSpec.describe KB::HubspotRelationship do
  before do
    client = described_class.send(:kb_client)
    connection = client.send('connection')
    connection.builder.adapter :test, stubs
  end

  after { described_class.send(:remove_instance_variable, :@kb_client) }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:model) { :policies }
  let(:key) { 'policy_key' }
  let(:resource_path) { "/v1/hubspot/#{model}/#{key}/relationship" }
  let(:api_response) do
    [200, { 'Content-Type': 'application/json' }, { 'kbKey' => key, 'hubspotId' => '90872363' }.to_json]
  end

  describe '.find' do
    subject(:find) { described_class.find(model, key) }

    it 'returns a HubspotRelationship instance' do
      stubs.get(resource_path) { api_response }

      expect(find).to be_a described_class
      stubs.verify_stubbed_calls
    end

    it 'returns the hubspot_id value' do
      stubs.get(resource_path) { api_response }

      expect(find.hubspot_id).to eq '90872363'
      stubs.verify_stubbed_calls
    end

    context 'when there is no relationship' do
      let(:key) { '6bf8b830-e57a-11ec-8fea-0242ac120002' }
      let(:api_response) do
        [404, { 'Content-Type': 'application/json' },
         {
           status: 404,
           error: 'Not Found',
           message: 'No message available',
           path: '/v1/hubspot/policies/6bf8b830-e57a-11ec-8fea-0242ac120002/relationship'
         }.to_json]
      end

      it 'raise the KB::ResourceNotFound error' do
        stubs.get(resource_path) { api_response }

        expect { find }.to raise_error(KB::ResourceNotFound)
        stubs.verify_stubbed_calls
      end
    end
  end
end
