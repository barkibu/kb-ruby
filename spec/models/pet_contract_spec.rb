require 'spec_helper'

RSpec.describe KB::PetContract do
  describe '.find_by_contract_number' do
    subject(:find_by_contract_number) { described_class.find_by_contract_number(contract_number) }

    before do
      client = described_class.send(:kb_client)
      connection = client.send('connection')
      connection.builder.adapter :test, stubs
    end

    after { described_class.send(:remove_instance_variable, :@kb_client) }

    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new
    end
    let(:contract_number) { 'MyContractNumber' }
    let(:contract_resource) do
      { 'key' => 'contract_key', 'contract_number' => contract_number, 'plan_key' => 'plan_key' }
    end
    let(:resource_path) { "/v1/petcontracts/contractnumber/#{contract_number}" }
    let(:api_response) { [200, { 'Content-Type': 'application/json' }, contract_resource.to_json] }

    it 'passes locale as params' do
      stubs.public_send(:get, resource_path) { api_response }

      expect(find_by_contract_number).to be_a described_class
      stubs.verify_stubbed_calls
    end
  end
end
