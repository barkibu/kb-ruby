require 'spec_helper'
require 'byebug'
RSpec.describe KB::UniquenessValidator do
  subject(:model) do
    model_class.new(phone_number: phone_number, prefix_phone_number: prefix_phone_number, &:validate)
  end

  include_context 'with Mock ActiveRecord Class'

  let(:model_class) do
    Class.new(active_record_class) do
      include KB::Concerns::AsKBWrapper

      wrap_kb model: KB::Pet

      attribute :phone_number, :string
      attribute :prefix_phone_number, :string
    end.tap do |record_class| # rubocop:disable Style/MultilineBlockChain
      record_class.validates :phone_number, 'kb/uniqueness': uniqueness_validation_options
    end
  end
  let(:phone_number) { '683123123' }
  let(:prefix_phone_number) { '+34' }

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Tests::FakeApi)
  end

  around do |example|
    snapshot = KB::Tests::FakeApi.snapshot()
    stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Tests::FakeApi)
    example.run
    KB::Tests::FakeApi.restore snapshot
  end

  context 'with no option provided' do
    let(:uniqueness_validation_options) { true }

    context 'with no record matching in API' do
      it 'mark the record as valid' do
        expect(model.valid?).to be true
      end
    end

    context 'with a record already existing in API' do
      before do
        KB::Pet.create(phone_number: phone_number)
      end

      it 'mark the attribute as taken' do
        expect(model.errors.errors).to include(have_attributes(attribute: :phone_number, type: :taken))
      end
    end
  end

  context 'with scope provided' do
    let(:uniqueness_validation_options) { { scope: :prefix_phone_number } }

    context 'with a record partially matching in API' do
      before do
        KB::Pet.create(phone_number: phone_number)
      end

      it 'mark the record as valid' do
        expect(model.valid?).to be true
      end
    end

    context 'with a record matching within the scope in API' do
      before do
        KB::Pet.create(phone_number: phone_number, prefix_phone_number: prefix_phone_number)
      end

      it 'mark the attribute as taken' do
        expect(model.errors.errors).to include(have_attributes(attribute: :phone_number, type: :taken))
      end
    end
  end
end
