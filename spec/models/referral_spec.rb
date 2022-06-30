require 'spec_helper'

RSpec.describe KB::Referral do
  let(:base_url) { 'https://test_api_barkkb.com/v1' }

  describe '.create' do
    subject(:create) { described_class.create('pet_parent_key', attributes) }

    let(:attributes) do
      {
        referred_key: 'referred_key',
        type: 'pet'
      }
    end

    let(:request_body) do
      {
        'referredKey' => 'referred_key',
        'type' => 'pet'
      }
    end

    let(:response_body) do
      {
        'key' => 'key',
        'referralKey' => 'pet_parent_key',
        'referredKey' => 'referred_key',
        'type' => 'pet',
        'joinedAt' => '2022-06-28T09:00:00'
      }
    end

    before do
      stub_request(:post, "#{base_url}/petparents/pet_parent_key/referrals")
        .with(body: request_body.to_json)
        .to_return(status: 200, body: response_body.to_json)
    end

    it 'returns attributes of the created referral' do
      expect(create).to eq({
                             joined_at: '2022-06-28T09:00:00', key: 'key', referred_key: 'referred_key',
                             referral_key: 'pet_parent_key', type: 'pet'
                           })
    end
  end
end
