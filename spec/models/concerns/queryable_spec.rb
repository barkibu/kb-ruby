require 'spec_helper'

RSpec.describe KB::Queryable do
  subject(:exposed_kb_client) { including_class.exposed_client }

  include_context 'with KB Models Queryable Concerns'

  let(:invalid_class) do
    including_class_factory do |class_self|
      class_self.define_singleton_method(:exposed_client) do
        kb_client
      end
    end
  end
  let(:including_class) { valid_class }

  let(:valid_class) do
    including_class_factory(client: :pet_parent) do |class_self|
      class_self.define_singleton_method(:exposed_client) do
        kb_client
      end
    end
  end

  it 'exposes `kb_api` privately to configure the client on the including class' do
    expect(including_class.private_methods).to include(:kb_api)
  end

  context 'when included in a class not configuring the client' do
    let(:including_class) { invalid_class }

    it 'accessing exposed client raises an error' do
      expect { exposed_kb_client }.to raise_exception KB::Queryable::KBClientNotSetException
    end
  end

  context 'when included in a class configuring the client' do
    let(:including_class) { valid_class }

    it 'makes the client available on Class level' do
      expect(exposed_kb_client).to be kb_client
    end
  end

  describe '#from_api' do
    subject(:from_api) { valid_class.from_api(attributes) }

    it 'returns a persited instance' do
      expect(from_api).to be_persisted
    end

    it 'returns an instance with no previous changes' do
      expect(from_api.previous_changes).to be_empty
    end
  end
end
