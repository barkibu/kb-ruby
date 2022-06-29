require 'spec_helper'

RSpec.describe KB::PetParent do
  let(:base_url) { 'https://test_api_barkkb.com/v1' }

  describe '#referrals' do
    subject(:referrals) { pet_parent.referrals }

    let(:pet_parent) { described_class.new(key: pet_parent_key) }
    let(:pet_parent_key) { 'pet_parent_key' }

    context 'when no referrals exist for pet parent' do
      before do
        stub_request(:get, "#{base_url}/petparents/#{pet_parent_key}/referrals")
          .to_return(status: 200, body: '[]')
      end

      it { is_expected.to be_empty }
    end

    context 'when referrals exist for pet parent' do
      let(:referrals_response) do
        [
          {
            key: 'key_1',
            referralKey: pet_parent_key,
            referredKey: 'referred_pet_key_1',
            joinedAt: '2022-06-28T09:00:00',
            type: 'pet'
          },
          {
            key: 'key_2',
            referralKey: pet_parent_key,
            referredKey: 'referred_pet_key_2',
            joinedAt: '2022-06-29T00:00:00',
            type: 'pet'
          }
        ]
      end

      before do
        stub_request(:get, "#{base_url}/petparents/#{pet_parent_key}/referrals")
          .to_return(status: 200, body: referrals_response.to_json)
      end

      it 'returns two records' do
        expect(referrals.size).to eq 2
      end

      it 'returns KB::Referral records' do
        expect(referrals).to all(be_a(KB::Referral))
      end

      it 'sets attributes for first model' do
        expect(referrals.first).to have_attributes(
          key: 'key_1',
          referral_key: pet_parent_key,
          referred_key: 'referred_pet_key_1',
          joined_at: Date.new(2022, 6, 28),
          type: 'pet'
        )
      end

      it 'sets attributes for the second model' do
        expect(referrals.last).to have_attributes(
          key: 'key_2',
          referral_key: pet_parent_key,
          referred_key: 'referred_pet_key_2',
          joined_at: DateTime.new(2022, 6, 29),
          type: 'pet'
        )
      end
    end
  end
end
