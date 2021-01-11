shared_context 'with KB Models Queryable Concerns' do
  let(:kb_client) { instance_double 'KB::Client' }
  let(:api_exception) { StandardError.new 'An Exception' }

  let(:attributes) { { foo: 'bar', partner: 'BBF' } }
  let(:key) { 'key' }

  def including_class_factory(concern: described_class, client: nil)
    allow(KB::ClientResolver).to receive(client).and_return kb_client if client.present?

    including_class = Class.new(KB::BaseModel) do
      include concern

      kb_api client if client.present?

      yield self if block_given?
    end

    allow(including_class).to receive(:attributes_from_response).and_return({})

    including_class
  end
end
