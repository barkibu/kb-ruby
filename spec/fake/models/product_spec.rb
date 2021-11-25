require 'spec_helper'
require 'kb-fake'

RSpec.describe KB::Product do
  around do |example|
    snapshot = KB::Fake::Api.snapshot()
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::Api)
    example.run
    KB::Fake::Api.restore snapshot
  end

  describe '.all' do
    subject(:all_products) { described_class.all(params) }

    let(:params) { {} }

    context 'with no country code provided' do
      it 'raises a KB::Error' do
        expect { all_products }.to raise_exception(KB::Error)
      end
    end

    context 'with a non valid country code' do
      let(:params) { { country: 'gal' } }

      it 'raises a KB::UnprocessableEntityError' do
        expect { all_products }.to raise_exception(KB::UnprocessableEntityError)
      end
    end
  end
end
