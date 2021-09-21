require 'spec_helper'
require 'kb-fake'

RSpec.describe KB::PetParent do
  around do |example|
    snapshot = KB::Fake::Api.snapshot()
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::Api)
    example.run
    KB::Fake::Api.restore snapshot
  end

  describe '#upsert' do
    subject(:upserted_pet_parent) { described_class.upsert(attributes.merge(first_name: first_name)) }

    let(:attributes) do
      { phone_number: '683123123', prefix_phone_number: '+34', email: 'foo@example.com' }
    end
    let(:first_name) { 'JMJ' }

    context 'with an existing phone pair' do
      before { existing_pet_parent }

      let(:existing_pet_parent) { described_class.create(attributes) }

      it 'return the existing PetParent' do
        expect(upserted_pet_parent.key).to eq(existing_pet_parent[:key])
      end

      it 'updates the entity with the provided properties' do
        expect(upserted_pet_parent.first_name).to eq(first_name)
      end

      context 'updating the phone number' do
        subject(:upserted_pet_parent) { described_class.upsert(attributes.merge(phone_number: '680000000')) }

        it 'raises an error' do
          expect do
            upserted_pet_parent
          end.to raise_error(KB::UnprocessableEntityError, 'Phone number can not be overridden')
        end
      end

      context 'updating the email' do
        subject(:upserted_pet_parent) { described_class.upsert(attributes.merge(email: 'bar@example.com')) }

        it 'raises an error' do
          expect { upserted_pet_parent }.to raise_error(KB::UnprocessableEntityError, 'Email can not be overridden')
        end
      end
    end

    context 'with an new phone pair' do
      it 'return a new PetParent' do
        %w[111111111 222222222 333333333].each do |phone|
          described_class.create(phone_number: phone, prefix_phone_number: '+34')
        end
        existing_keys = described_class.all.map(&:key)
        expect(existing_keys).not_to include(upserted_pet_parent.key)
      end

      it 'create an entity with the provided properties' do
        expect(upserted_pet_parent.first_name).to eq(first_name)
      end
    end
  end
end
