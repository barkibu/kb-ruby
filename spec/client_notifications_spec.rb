require 'spec_helper'

RSpec.describe KB::Client do
  subject(:client) { described_class.new('http://kb.test/v1/pets', api_key: 'test') }

  let(:events) { [] }

  around do |example|
    subscriber = ActiveSupport::Notifications.subscribe(described_class::REQUEST_EVENT) do |*, payload|
      events << payload
    end
    example.run
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  describe 'request.kb_client notifications' do
    it 'describes a successful GET' do
      stub_request(:get, 'http://kb.test/v1/pets/birthdays?month=9')
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      client.request('birthdays', filters: { month: 9 })

      expect(events.last).to eq(verb: :get, path: 'birthdays', base_url: 'http://kb.test/v1/pets',
                                cache_hit: false, status: 200, connections: ['new'])
    end

    it 'describes a write without a cache flag' do
      stub_request(:post, 'http://kb.test/v1/pets').to_return(status: 201, body: '{}',
                                                              headers: { 'Content-Type' => 'application/json' })

      client.create(name: 'Rex')

      expect(events.last).to eq(verb: :post, path: '', base_url: 'http://kb.test/v1/pets', status: 201,
                                connections: ['new'])
    end

    it 'keeps the status code and the exception when the API answers an error' do
      stub_request(:get, 'http://kb.test/v1/pets/missing').to_return(status: 404, body: 'Not Found')

      raised = nil
      begin
        client.find('missing')
      rescue Faraday::Error => e
        raised = e.class
      end

      expect(
        raised: raised, status: events.last[:status], exception_class: events.last[:exception_object].class
      ).to eq(raised: Faraday::ResourceNotFound, status: 404, exception_class: Faraday::ResourceNotFound)
    end

    it 'still raises to the caller when the event has subscribers' do
      stub_request(:get, 'http://kb.test/v1/pets/missing').to_return(status: 404, body: 'Not Found')

      expect { client.find('missing') }.to raise_error(Faraday::ResourceNotFound)
    end
  end
end
