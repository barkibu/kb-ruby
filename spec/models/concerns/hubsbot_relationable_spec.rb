require 'spec_helper'

RSpec.describe KB::HubspotRelationable do
  including_class = Class.new(KB::BaseModel) do
    include KB::HubspotRelationable

    hubspot_model :policies

    attribute :key, :string
    attribute :partner, :string

    def self.attributes_from_response(attributes)
      attributes.slice(:foo, :partner)
    end
  end

  subject(:hubspot) { including_class.hubspot }

  let(:kb_client) { instance_double 'KB::Client' }
  let(:api_exception) { StandardError.new 'An Exception' }

  let(:attributes) { { foo: 'bar', partner: 'BBF' } }
  let(:key) { 'key' }

  def including_class_factory(concern: described_class, client: nil)
    allow(KB::ClientResolver).to receive(client).and_return kb_client if client.present?

    including_class = Class.new(KB::BaseModel) do
      include concern

      kb_api client if client.present?

      attribute :foo, :string
      attribute :partner, :string

      yield self if block_given?

      def self.attributes_from_response(attributes)
        attributes.slice(:foo, :partner)
      end
    end

    allow(including_class).to receive(:attributes_from_response).and_call_original
    including_class
  end

  let(:including_class) { including_class_factory(client: :consultation) }
  let(:found_entity) { { key: key, foo: 'bar', some_field: 'a field we just ignore' } }

  before do
    allow(kb_client).to receive(:find).and_return(found_entity)
    allow(including_class).to receive(:new).and_call_original
  end

  it 'calls `find` on the configured client' do
    find
    expect(kb_client).to have_received(:find).with(key, {})
  end
end
