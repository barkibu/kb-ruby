require 'spec_helper'

RSpec.describe KB::Assessment do
  before do
    client = described_class.send(:kb_client)
    connection = client.send('connection')
    connection.builder.adapter :test, stubs
  end

  after { described_class.send(:remove_instance_variable, :@kb_client) }

  let(:stubs) do
    Faraday::Adapter::Test::Stubs.new
  end
  let(:resources) { [{ 'my' => 'first_resource' }, { 'my' => 'second_resource' }] }
  let(:resource_path) { '/v1/consultations' }

  describe '#all' do
    subject(:all) { described_class.all(filters) }

    let(:api_response) { [200, { 'Content-Type': 'application/json' }, resources.to_json] }
    let(:filters) { { foo: 'bar' } }

    it_behaves_like 'Localizable Request'
  end

  describe '#find' do
    subject(:find) { described_class.find(key) }

    let(:api_response) { [200, { 'Content-Type': 'application/json' }, resources.first] }
    let(:key) { 'bar' }
    let(:resource_path) { '/v1/consultations/bar' }

    it_behaves_like 'Localizable Request'
  end
end
