require 'spec_helper'
require 'barkibu-kb-fake'

RSpec.describe KB::PetContract do
  include_context 'with a mock as KB API'

  describe '.search' do
    subject(:search) { described_class.search(chip: chip) }

    let(:chip) { '123451234512345' }
    let(:page) { 1 }
    let(:size) { 5 }
    let!(:pet) { KB::Pet.new(KB::Pet.create(chip: chip)) }

    it 'returns a hash with pagination data' do
      expect(search).to include(page: instance_of(Integer),
                                total: instance_of(Integer))
    end

    context 'when there are no contracts for the given chip' do
      before do
        another_pet = KB::Pet.new(KB::Pet.create(chip: chip))
        described_class.create(pet_key: another_pet.key)
      end

      it 'returns a hash including an empty array' do
        expect(search[:elements]).to eq([])
      end
    end

    context 'when there is a contract for the given chip' do
      let!(:contract) { described_class.new(described_class.create(pet_key: pet.key)) }

      it 'returns a hash including an array with that contract' do
        expect(search[:elements].map(&:key)).to eq([contract.key])
      end
    end

    context 'when there are several pages of contracts' do
      let(:size) { 5 }

      before { (size * 3).times { described_class.create(pet_key: pet.key) } }

      context 'when the second page is requested' do
        subject(:search) { described_class.search(chip: chip, page: page, size: size) }

        let(:page) { 2 }

        it 'returns a hash including an array with many items' do
          expect(search[:elements]).to be_many
        end

        it 'returns a hash including an array of PetContracts' do
          expect(search[:elements]).to all(be_an_instance_of(described_class))
        end
      end
    end
  end
end
