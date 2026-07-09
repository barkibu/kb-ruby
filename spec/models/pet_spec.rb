require 'spec_helper'

RSpec.describe KB::Pet do
  let(:base_url) { 'https://test_api_barkkb.com/v1/pets' }
  let(:pet_key) { 'pet-uuid-123' }
  let(:destination_pet_parent_key) { 'parent-uuid-456' }

  describe '.transfer' do
    subject(:transfer) do
      described_class.transfer(pet_key: pet_key, destination_pet_parent_key: destination_pet_parent_key)
    end

    context 'when the transfer succeeds' do
      before do
        stub_request(:post, "#{base_url}/transfer")
          .to_return(status: 204, body: '')
      end

      it 'POSTs to the transfer endpoint with camelCase keys' do
        transfer
        expect(
          a_request(:post, "#{base_url}/transfer")
            .with(body: { petKey: pet_key, destinationPetParentKey: destination_pet_parent_key }.to_json)
        ).to have_been_made
      end

      it { is_expected.to be_nil }
    end

    context 'when the pet is not found' do
      before do
        stub_request(:post, "#{base_url}/transfer")
          .to_return(status: 404, body: '{}')
      end

      it { expect { transfer }.to raise_error(KB::ResourceNotFound) }
    end

    context 'when the destination parent is invalid' do
      before do
        stub_request(:post, "#{base_url}/transfer")
          .to_return(status: 422, body: '{}')
      end

      it { expect { transfer }.to raise_error(KB::UnprocessableEntityError) }
    end
  end

  describe '#pet_parent' do
    subject(:pet) { described_class.new(key: pet_key, pet_parent_key: pet_parent_key) }

    let(:pet_parent_key) { 'parent-uuid-456' }
    let(:pet_parent_url) { "https://test_api_barkkb.com/v1/petparents/#{pet_parent_key}" }

    before do
      stub_request(:get, pet_parent_url)
        .to_return(status: 200, body: { key: pet_parent_key }.to_json)
    end

    it 'returns the pet parent' do
      expect(pet.pet_parent).to have_attributes(key: pet_parent_key)
    end

    it 'memoizes the lookup' do
      2.times { pet.pet_parent }
      expect(a_request(:get, pet_parent_url)).to have_been_made.once
    end
  end
end
