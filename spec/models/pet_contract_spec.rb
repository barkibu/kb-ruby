require 'spec_helper'

RSpec.describe KB::PetContract do
  describe '.find_by_contract_number' do
    subject(:find_by_contract_number) { described_class.find_by_contract_number(contract_number) }

    before do
      stub_request(:get, "https://test_api_barkkb.com/v1/petcontracts/contractnumber/#{contract_number}")
        .to_return(status: 200, body: contract_resource.to_json)
    end

    let(:contract_number) { 'MyContractNumber' }
    let(:contract_resource) do
      { 'key' => 'contract_key', 'contract_number' => contract_number, 'plan_key' => 'plan_key' }
    end

    it 'returns a KB::PetContract' do
      expect(find_by_contract_number).to be_a described_class
    end
  end

  describe '#hubspot_id' do
    subject(:hubspot_id) { described_class.new.hubspot_id }

    let(:hubspot_relationship) { KB::HubspotRelationship.new(hubspot_id: '90872363') }

    it 'returns the hubspot_id from the relationship' do
      allow(KB::HubspotRelationship).to receive(:find).and_return(hubspot_relationship)

      expect(hubspot_id).to eq '90872363'
    end

    context 'when there is no relationship' do
      before do
        allow(KB::HubspotRelationship).to receive(:find).and_raise(KB::ResourceNotFound)
      end

      it 'returns nil' do
        expect(hubspot_id).to eq nil
      end
    end
  end

  describe '==' do
    it 'returns true for two contracts with the same key' do
      contract1 = described_class.new(key: 'test')
      contract2 = described_class.new(key: 'test')
      expect(contract1 == contract2).to be true
    end

    it 'returns false for two contracts with different key' do
      contract1 = described_class.new(key: 'test1')
      contract2 = described_class.new(key: 'test2')
      expect(contract1 == contract2).to be false
    end

    it 'returns false for two objects of different classes' do
      contract = described_class.new(key: 'test1')
      pet = KB::Pet.new(key: 'test2')
      expect(contract == pet).to be false
    end
  end

  describe '.search' do
    subject(:search) { described_class.search(chip: chip, page: page, size: size) }

    let(:chip) { '123451234512345' }
    let(:page) { 2 }
    let(:size) { 100 }
    let(:found_contracts) { [] }
    let(:response_body) do
      { page: page,
        total: found_contracts.size,
        elements: found_contracts }
    end

    before do
      stub_request(:get, 'https://test_api_barkkb.com/v1/petcontracts/search')
        .with(query: hash_including(chip: chip, page: page.to_s, size: size.to_s))
        .to_return(status: 200, body: response_body.to_json)
    end

    it 'returns a hash with pagination data' do
      expect(search).to include(page: instance_of(Integer),
                                total: instance_of(Integer))
    end

    context 'when there are no found contracts' do
      it 'returns a hash including an empty array' do
        expect(search[:elements]).to eq([])
      end
    end

    context 'when there are found contracts' do
      let(:found_contracts) { [{ key: 'dummy1' }, { key: 'dummy2' }] }

      it 'returns a hash including an array of PetContracts' do
        expect(search[:elements]).to all(be_an_instance_of(described_class))
      end
    end
  end
end
