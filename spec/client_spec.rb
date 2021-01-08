require 'spec_helper'

RSpec.describe KB::Client do
  subject(:client) { described_class.new(base_url, api_key: api_key) }

  let(:path) { '/v4/resource' }
  let(:api_host) { 'http://myapi.com' }
  let(:base_url) { api_host + path }
  let(:api_key) { 'MyApiKey' }
  let(:authorization_headers) { { 'x-api-key': api_key } }

  let(:stubs) do
    Faraday::Adapter::Test::Stubs.new
  end

  before(:all) do
    I18n.available_locales = %i[en es]
    I18n.default_locale = :en
  end

  before do
    connection = client.send('connection')
    connection.builder.adapter :test, stubs
  end

  after do
    Faraday.default_connection = nil
  end

  describe '#all' do
    subject(:all) { client.all(filters) }

    let(:api_response) { [200, { 'Content-Type': 'application/json' }, resources.to_json] }
    let(:api_error) { [422, {}, 'Something went wrong'] }
    let(:filters) { { foo: 'bar' } }
    let(:resources) { [{ my: 'first_resource' }, { my: 'second_resource' }] }

    it_behaves_like 'Localizable Request' do
      let(:resource_path) { path }
    end

    it 'launches a GET request' do
      stubs.get(path) { |_env| api_response }
      all
      stubs.verify_stubbed_calls
    end

    it 'passes filters as params' do
      stubs.get(path) do |env|
        expect(env.params).to include filters.with_indifferent_access
        api_response
      end
      all
    end

    it 'passes the authorization headers' do
      stubs.get(path) do |env|
        expect(env.request_headers).to include authorization_headers
        api_response
      end
      all
    end

    context 'with a successful request' do
      it 'returns the parsed json' do
        stubs.get(path) { |_env| api_response }
        expect(all).to eq(resources.map(&:with_indifferent_access))
      end
    end

    context 'with a failing api request' do
      it 'triggers an error' do
        stubs.get(path) { |_env| api_error }
        expect { all }.to raise_error Faraday::ClientError
      end
    end
  end

  describe '#find' do
    subject(:find) { client.find(key) }

    let(:api_response) { [200, { 'Content-Type': 'application/json' }, resource.to_json] }
    let(:api_error) { [404, {}, 'Not Found'] }
    let(:key) { 'identifying_key' }
    let(:resource) { { key: key, foo: 'bar' } }
    let(:resource_path) { "#{path}/#{key}" }

    it_behaves_like 'Localizable Request'

    it 'launches a GET request' do
      stubs.get(resource_path) { |_env| api_response }
      find
      stubs.verify_stubbed_calls
    end

    it 'passes the authorization headers' do
      stubs.get(resource_path) do |env|
        expect(env.request_headers).to include authorization_headers
        api_response
      end
      find
    end

    context 'with a successful request' do
      it 'returns the parsed json' do
        stubs.get(resource_path) { |_env| api_response }
        expect(find).to eq(resource.with_indifferent_access)
      end
    end

    context 'with a failing api request' do
      it 'triggers an error' do
        stubs.get(resource_path) { |_env| api_error }
        expect { find }.to raise_error Faraday::ClientError
      end
    end
  end

  describe '#create' do
    subject(:create) { client.create(attributes) }

    let(:api_response) { [201, { 'Content-Type': 'application/json' }, created_entity.to_json] }
    let(:api_error) { [422, {}, 'Invalid something'] }
    let(:attributes) { { attribute_a: 'value 1', foo: 'bar' } }
    let(:created_entity) { attributes.merge(key: 'key') }

    it_behaves_like 'Localizable Request', :post do
      let(:resource_path) { path }
    end

    it 'launches a POST request' do
      stubs.post(path) { |_env| api_response }
      create
      stubs.verify_stubbed_calls
    end

    it 'passes the authorization headers' do
      stubs.post(path) do |env|
        expect(env.request_headers).to include authorization_headers
        api_response
      end
      create
    end

    context 'with a successful request' do
      it 'returns the parsed json' do
        stubs.post(path) { |_env| api_response }
        expect(create).to eq(created_entity.with_indifferent_access)
      end
    end

    context 'with a failing api request' do
      it 'triggers an error' do
        stubs.post(path) { |_env| api_error }
        expect { create }.to raise_error Faraday::ClientError
      end
    end
  end
end
