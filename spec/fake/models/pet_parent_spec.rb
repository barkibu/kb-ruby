require 'spec_helper'
require 'barkibu-kb-fake'

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
      let(:phone_attributes) do
        { phone_number: '680000000', prefix_phone_number: '+34' }
      end

      it 'return the existing PetParent' do
        expect(upserted_pet_parent.key).to eq(existing_pet_parent[:key])
      end

      it 'updates the entity with the provided properties' do
        expect(upserted_pet_parent.first_name).to eq(first_name)
      end

      context 'when updating with a non existent phone number' do
        subject(:upserted_pet_parent) { described_class.upsert(attributes.merge(phone_attributes)) }

        it 'updates the entity with the provided phone number' do
          expect(upserted_pet_parent.phone_number).to eq(phone_attributes[:phone_number])
        end
      end

      context 'when updating with an existent phone number' do
        subject(:upserted_pet_parent) do
          described_class.upsert(attributes.merge(phone_number: phone_attributes[:phone_number]))
        end

        before { other_pet_parent }

        let(:other_pet_parent) { described_class.create(phone_attributes) }

        it 'raises an error' do
          expect { upserted_pet_parent }.to raise_error(KB::ConflictError)
        end
      end

      context 'when updating the email' do
        subject(:upserted_pet_parent) { described_class.upsert(attributes.merge(email: 'bar@example.com')) }

        it 'raises an error' do
          expect { upserted_pet_parent }.to raise_error(KB::UnprocessableEntityError)
        end
      end

      context 'when updating an unrestricted field of a pet parent only specifying phone part of its identification' do
        subject(:upserted_pet_parent) do
          described_class.upsert(partial_identification_attributes.merge(last_name: 'Doe'))
        end

        let(:partial_identification_attributes) { attributes.tap { |atts| atts.delete(:email) } }

        it 'updates the entity with the unrestricted field' do
          expect(upserted_pet_parent.last_name).to eq('Doe')
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

  describe '#referrals' do
    before { existing_pet_parent }

    let(:attributes) do
      { phone_number: '683123123', prefix_phone_number: '+34', email: 'foo@example.com' }
    end
    let(:existing_pet_parent) { described_class.new described_class.create(attributes) }

    context 'with no referrals' do
      it 'returns an empty list' do
        expect(existing_pet_parent.referrals).to eq([])
      end
    end

    context 'with a referral' do
      before do
        KB::Referral.create(existing_pet_parent.key,
                            { type: 'pet', referred_key: pet_key, joined_at: '2018-01-01T17:09:42.411' })
      end

      let(:pet_key) { 'pet_key' }

      it 'returns the referral of the pet parent' do
        expect(existing_pet_parent.referrals.length).to eq(1)
      end

      it 'returns the referral with all the attributes' do
        expect(existing_pet_parent.referrals.first).to have_attributes(
          'type' => 'pet',
          'referral_key' => existing_pet_parent.key,
          'referred_key' => pet_key,
          'joined_at' => '2018-01-01'.to_date
        )
      end
    end
  end
end
