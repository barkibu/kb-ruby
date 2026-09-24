require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
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

  before do
    # Both shared connections: keep-alive, and plain net_http for calls with their own read_timeout.
    [client.send(:connection), client.send(:connection, 30)].each { |c| c.builder.adapter :test, stubs }
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

  describe '#upsert' do
    subject(:upsert) { client.upsert(attributes) }

    let(:api_response) { [200, { 'Content-Type': 'application/json' }, upserted_entity.to_json] }
    let(:api_error) { [422, {}, 'Invalid something'] }
    let(:attributes) { { attribute_a: 'value 1', foo: 'bar' } }
    let(:upserted_entity) { attributes.merge(key: 'key') }

    it 'launches a PUT request' do
      stubs.put(path) { |_env| api_response }
      upsert
      stubs.verify_stubbed_calls
    end

    it 'passes the authorization headers' do
      stubs.put(path) do |env|
        expect(env.request_headers).to include authorization_headers
        api_response
      end
      upsert
    end

    context 'with a successful request' do
      it 'returns the parsed json' do
        stubs.put(path) { |_env| api_response }
        expect(upsert).to eq(upserted_entity.with_indifferent_access)
      end
    end

    context 'with a failing api request' do
      it 'triggers an error' do
        stubs.put(path) { |_env| api_error }
        expect { upsert }.to raise_error Faraday::ClientError
      end
    end
  end

  describe '#destroy' do
    subject(:destroy) { client.destroy(key) }

    let(:api_response) { [204, {}] }
    let(:key) { 'identifying_key' }
    let(:resource_path) { "#{path}/#{key}" }

    it 'launches a DELETE request' do
      stubs.delete(resource_path) { |_env| api_response }
      destroy
      stubs.verify_stubbed_calls
    end

    it 'passes the authorization headers' do
      stubs.delete(resource_path) do |env|
        expect(env.request_headers).to include authorization_headers
        api_response
      end
      destroy
    end

    context 'with a successful request' do
      it 'returns no content' do
        stubs.delete(resource_path) { |_env| api_response }
        expect(destroy).to eq(nil)
      end
    end
  end

  describe '#request' do
    let(:api_response) { [200, { 'Content-Type': 'application/json' }, { elements: [] }.to_json] }
    let(:sub_path) { 'birthdays' }
    let(:filters) { { month: 9, day: 22 } }

    it 'launches a GET request on the sub path with filters as params' do
      stubs.get("#{path}/#{sub_path}") do |env|
        expect(env.params).to include filters.transform_keys(&:to_s).transform_values(&:to_s)
        api_response
      end
      client.request(sub_path, filters: filters)
      stubs.verify_stubbed_calls
    end

    it 'uses the global read timeout by default' do
      stubs.get("#{path}/#{sub_path}") do |env|
        expect(env.request.read_timeout).to eq KB.config.request.read_timeout
        api_response
      end
      client.request(sub_path, filters: filters)
    end

    it 'overrides only the read timeout for that call when given' do
      stubs.get("#{path}/#{sub_path}") do |env|
        expect(
          open: env.request.open_timeout, write: env.request.write_timeout, read: env.request.read_timeout
        ).to eq(open: KB.config.request.connect_timeout, write: KB.config.request.write_timeout, read: 30)
        api_response
      end
      client.request(sub_path, filters: filters, read_timeout: 30)
    end

    it 'does not leak the override into later calls' do
      stubs.get("#{path}/#{sub_path}") { |_env| api_response }
      client.request(sub_path, filters: filters, read_timeout: 30)
      stubs.get("#{path}/other") do |env|
        expect(env.request.read_timeout).to eq KB.config.request.read_timeout
        api_response
      end
      client.request('other')
    end

    it 'passes the override on non-GET requests too' do
      stubs.post("#{path}/#{sub_path}") do |env|
        expect(env.request.read_timeout).to eq 30
        api_response
      end
      client.request(sub_path, filters: filters, method: :post, read_timeout: 30)
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
