shared_context 'KB Models Queryable Concerns' do
  let(:kb_client) { double 'KB::Client' }
  let(:api_exception) { StandardError.new 'An Exception' }

  let(:attributes) { { foo: 'bar', partner: 'BBF' } }
  let(:key) { 'key' }

  def including_class_factory(concern: described_class, client: nil)
    allow(KB::ClientResolver).to receive(client).and_return kb_client if client.present?
    Class.new(KB::BaseModel) do
      include concern

      kb_api client if client.present?

      def self.attributes_from_response(_response)
        {}
      end

      yield self if block_given?
    end
  end
end
