require 'spec_helper'

RSpec.describe KB::Hubspot do
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

  describe '.relationship' do
    subject(:relationship) { described_class.relationship(model, key) }

    it 'returns a Hubspot instance' do
      stubs.public_send(:get, resource_path) { api_response }

      expect(relationship).to be_a described_class
      stubs.verify_stubbed_calls
    end

    it 'returns the hubspot_id value' do
      stubs.public_send(:get, resource_path) { api_response }

      expect(relationship.hubspot_id).to eq '90872363'
      stubs.verify_stubbed_calls
    end
  end
end
