require 'spec_helper'
require 'socket'
require 'datadog'
require 'kb/instrumentation/datadog'

RSpec.describe KB::Instrumentation::Datadog do
  subject(:client) { KB::Client.new(base_url, api_key: 'test') }

  let(:base_url) { 'http://kb.test/v1/pets' }
  let(:spans) { [] }

  # Real spans, nothing sent anywhere: test mode with a transport that swallows traces.
  def configure_tracing(enabled:)
    null_transport = Class.new do
      def send_traces(_traces)
        []
      end
    end.new
    Datadog.configure do |c|
      c.diagnostics.startup_logs.enabled = false
      c.tracing.enabled = enabled
      c.tracing.test_mode.enabled = true
      c.tracing.test_mode.writer_options = { transport: null_transport }
    end
  end

  before do
    configure_tracing(enabled: true) unless Datadog.configuration.tracing.test_mode.enabled
    described_class.subscribe!
    # rspec-mocks hands the original call's keywords over as a trailing Hash.
    allow(Datadog::Tracing).to receive(:trace).and_wrap_original do |original, name, options = {}|
      span = original.call(name, **options)
      spans << span
      span
    end
  end

  after { described_class.unsubscribe! }

  def last_span
    spans.last
  end

  describe '.subscribe!' do
    it 'subscribes once' do
      described_class.subscribe!
      stub_request(:get, 'http://kb.test/v1/pets/birthdays')
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      client.request('birthdays')

      expect(spans.size).to eq(1)
    end

    it 'refuses to subscribe without a tracer loaded' do
      described_class.unsubscribe!
      hide_const('Datadog::Tracing')
      expect { described_class.subscribe! }.to raise_error(described_class::TracerMissing)
    end
  end

  describe '.resource_for' do
    def resource(verb, path)
      described_class.resource_for(base_url, verb, path)
    end

    it 'prefixes the base path and upcases the verb' do
      expect(resource(:get, 'birthdays')).to eq('GET /v1/pets/birthdays')
    end

    it 'collapses identifier segments so resources stay low-cardinality' do
      expect(resource(:get, '3f2b1c9e-8d7a-4b6c-9e1f-2a3b4c5d6e7f/contracts')).to eq('GET /v1/pets/?/contracts')
    end

    it 'handles the empty path used by #all, #create and #upsert' do
      expect(resource(:post, '')).to eq('POST /v1/pets')
    end
  end

  describe 'a successful GET' do
    before do
      stub_request(:get, 'http://kb.test/v1/pets/birthdays?month=9')
        .to_return(status: 200, body: { elements: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'emits one finished kb.client.request span describing the call' do
      client.request('birthdays', filters: { month: 9 })

      expect(
        name: last_span.name, resource: last_span.resource, type: last_span.type, status: last_span.status,
        finished: last_span.finished?, kind: last_span.get_tag('span.kind'),
        peer: last_span.get_tag('peer.service'), host: last_span.get_tag('peer.hostname'),
        code: last_span.get_tag('http.status_code'), cache_hit: last_span.get_tag('kb.cache_hit')
      ).to eq(
        name: 'kb.client.request', resource: 'GET /v1/pets/birthdays', type: 'http', status: 0,
        finished: true, kind: nil, peer: nil, host: 'kb.test', code: '200', cache_hit: 'false'
      )
    end

    it 'leaves the service unset so the span inherits the application service' do
      client.request('birthdays', filters: { month: 9 })
      expect(last_span.service).to eq(Datadog.configuration.service)
    end
  end

  # Funnel and Global Admin disable tracing outside production; the client must
  # behave exactly the same there.
  describe 'with tracing disabled' do
    around do |example|
      configure_tracing(enabled: false)
      example.run
    ensure
      configure_tracing(enabled: true)
    end

    before do
      stub_request(:get, 'http://kb.test/v1/pets/birthdays?month=9')
        .to_return(status: 200, body: { elements: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'still performs the call and returns the parsed body' do
      expect(client.request('birthdays', filters: { month: 9 })).to eq('elements' => [])
    end
  end

  describe 'a cached GET' do
    around do |example|
      KB.configure do |config|
        config.cache.instance = ActiveSupport::Cache::MemoryStore.new
        config.cache.expires_in = 60
      end
      example.run
    ensure
      KB.configure do |config|
        config.cache.instance = ActiveSupport::Cache::NullStore.new
        config.cache.expires_in = 0
      end
    end

    before do
      stub_request(:get, 'http://kb.test/v1/pets/some-key')
        .to_return(status: 200, body: { key: 'some-key' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'tags the second call as a cache hit and still emits a span for it' do
      client.find('some-key')
      client.find('some-key')

      expect(
        cache_hits: spans.map { |span| span.get_tag('kb.cache_hit') },
        second_status_code: last_span.get_tag('http.status_code')
      ).to eq(cache_hits: %w[false true], second_status_code: nil)
    end
  end

  describe 'an HTTP error' do
    before do
      stub_request(:get, 'http://kb.test/v1/pets/missing').to_return(status: 404, body: 'Not Found')
    end

    it 'marks the span as an error with the status code and the raised class' do
      raised = nil
      begin
        client.find('missing')
      rescue Faraday::Error => e
        raised = e.class
      end

      expect(
        raised: raised, status: last_span.status, code: last_span.get_tag('http.status_code'),
        error_type: last_span.get_tag('error.type')
      ).to eq(raised: Faraday::ResourceNotFound, status: 1, code: '404', error_type: 'Faraday::ResourceNotFound')
    end
  end

  describe 'a non-GET call' do
    before do
      stub_request(:post, 'http://kb.test/v1/pets').to_return(status: 201, body: '{}',
                                                              headers: { 'Content-Type' => 'application/json' })
    end

    it 'emits a span without a cache tag' do
      client.create(name: 'Rex')

      expect(
        resource: last_span.resource, code: last_span.get_tag('http.status_code'),
        cache_hit: last_span.get_tag('kb.cache_hit')
      ).to eq(resource: 'POST /v1/pets', code: '201', cache_hit: nil)
    end
  end

  describe 'a retried call' do
    around do |example|
      KB.config.request.retry_interval = 0
      example.run
    ensure
      KB.config.request.retry_interval = 0.1
    end

    it 'tags the retry count and the retried error on an otherwise successful span' do
      ok = { status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' } }
      stub_request(:get, 'http://kb.test/v1/pets/k').to_raise(Net::OpenTimeout).then.to_return(ok)

      client.find('k')

      expect(
        status: last_span.status, retries: last_span.get_metric('kb.retries') || last_span.get_tag('kb.retries'),
        errors: last_span.get_tag('kb.retry_errors')
      ).to eq(status: 0, retries: 1, errors: 'Net::OpenTimeout')
    end

    it 'adds no retry tags when the first attempt succeeds' do
      stub_request(:get, 'http://kb.test/v1/pets/k').to_return(status: 200, body: '{}',
                                                               headers: { 'Content-Type' => 'application/json' })

      client.find('k')

      expect(last_span.get_tag('kb.retries')).to be_nil
    end
  end

  # The case that motivated this module: a connect failure never reaches
  # Net::HTTP#request, so the Datadog Net::HTTP tracer never sees it. The
  # notification wraps the connect and the span records it.
  describe 'a connect failure' do
    let(:closed_port) do
      server = TCPServer.new('127.0.0.1', 0)
      port = server.addr[1]
      server.close
      port
    end
    let(:base_url) { "http://127.0.0.1:#{closed_port}/v1/pets" }

    around do |example|
      WebMock.allow_net_connect!
      example.run
    ensure
      WebMock.disable_net_connect!
    end

    it 'records the failure on the kb.client.request span' do
      raised = nil
      begin
        client.request('birthdays', filters: { month: 9 })
      rescue Faraday::Error => e
        raised = e.class
      end

      expect(
        raised: raised, status: last_span.status, error_type: last_span.get_tag('error.type'),
        code: last_span.get_tag('http.status_code'), resource: last_span.resource,
        retried: last_span.get_tag('kb.retry_errors')
      ).to eq(raised: Faraday::ConnectionFailed, status: 1, error_type: 'Faraday::ConnectionFailed',
              code: nil, resource: 'GET /v1/pets/birthdays', retried: 'Errno::ECONNREFUSED')
    end
  end
end
