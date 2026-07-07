require 'spec_helper'
require 'barkibu-kb-fake'

RSpec.describe KB::Pet do
  around do |example|
    snapshot = KB::Fake::Api.snapshot()
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::Api)
    example.run
    KB::Fake::Api.restore snapshot
  end

  describe '#upsert' do
    subject(:upserted_pet) { described_class.upsert(attributes.merge(mongrel: true, chip: 'my_chip')) }

    let(:attributes) do
      { name: 'fuffy', pet_parent_key: my_pet_parent_kb_uuid, mongrel: false }
    end

    context 'when pet parent not exists' do
      let(:my_pet_parent_kb_uuid) { 'new_pet_parent_key' }

      it 'raises a KB::UnprocessableEntityError' do
        expect { upserted_pet }.to raise_error(KB::UnprocessableEntityError)
      end
    end

    context 'when pet parent exists' do
      let(:existing_pet_parent) { KB::PetParent.create({}) }
      let(:my_pet_parent_kb_uuid) { existing_pet_parent[:key] }

      context 'when pet whose name exists' do
        let!(:existing_pet) { described_class.create(attributes) }

        it 'returns the existing_pet key' do
          expect(upserted_pet.key).to eq(existing_pet[:key])
        end

        it 'updates existing attributes' do
          expect(upserted_pet.mongrel).to eq(true)
        end

        it 'sets new attributes' do
          expect(upserted_pet.chip).to eq('my_chip')
        end
      end

      context 'when pet whose name does not exists' do
        before do
          3.times do |i|
            described_class.create(name: "Pet#{i}", pet_parent_key: existing_pet_parent[:key])
          end
        end

        it 'creates and returns a new Pet key' do
          existing_keys = described_class.all.map(&:key)
          expect(existing_keys).not_to include(upserted_pet.key)
        end

        it 'sets name attribute' do
          expect(upserted_pet.name).to eq('fuffy')
        end
      end
    end
  end

  describe '.transfer' do
    let(:source_parent) { KB::PetParent.create({}) }
    let(:destination_parent) { KB::PetParent.create({}) }
    let(:pet) { described_class.create(name: 'Buddy', pet_parent_key: source_parent[:key]) }

    context 'when the pet and destination parent exist' do
      it 'reassigns the pet to the destination parent' do
        described_class.transfer(pet_key: pet[:key], destination_pet_parent_key: destination_parent[:key])
        expect(described_class.find(pet[:key]).pet_parent_key).to eq(destination_parent[:key])
      end
    end

    context 'when the destination is the current parent (self-transfer)' do
      it 'does not change the pet parent' do
        described_class.transfer(pet_key: pet[:key], destination_pet_parent_key: source_parent[:key])
        expect(described_class.find(pet[:key]).pet_parent_key).to eq(source_parent[:key])
      end
    end

    context 'when the pet does not exist' do
      it 'raises KB::ResourceNotFound' do
        expect do
          described_class.transfer(pet_key: 'missing-key', destination_pet_parent_key: destination_parent[:key])
        end.to raise_error(KB::ResourceNotFound)
      end
    end

    context 'when the destination parent does not exist' do
      it 'raises KB::UnprocessableEntityError' do
        expect do
          described_class.transfer(pet_key: pet[:key], destination_pet_parent_key: 'missing-parent-key')
        end.to raise_error(KB::UnprocessableEntityError)
      end
    end
  end
end
