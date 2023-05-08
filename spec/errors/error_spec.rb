require 'spec_helper'
require 'byebug'
RSpec.describe KB::Error do
  describe '.from_faraday' do
    subject(:from_faraday) { described_class.from_faraday(exception) }

    let(:exception) { Faraday::Error.new('Boom', { status: status }) }
    let(:status) { 400 }

    it 'returns a KB::Error' do
      expect(from_faraday).to be_a(described_class)
    end

    context 'with a 404' do
      let(:status) { 404 }

      it 'returns a ResourceNotFound' do
        expect(from_faraday).to be_a(KB::ResourceNotFound)
      end
    end

    context 'with a 409' do
      let(:status) { 409 }

      it 'returns a ConflictError' do
        expect(from_faraday).to be_a(KB::ConflictError)
      end
    end

    context 'with a 422' do
      let(:status) { 422 }

      it 'returns a UnprocessableEntityError' do
        expect(from_faraday).to be_a(KB::UnprocessableEntityError)
      end
    end

    context 'with an empty server error' do
      let(:exception) { Faraday::TimeoutError.new }

      it 'returns a KB::Error' do
        expect(from_faraday).to be_a(described_class)
      end
    end
  end
end
