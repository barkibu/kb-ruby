require 'spec_helper'

RSpec.describe KB::ClientResolver do
  let(:context) { 'context' }
  let(:entity) { 'resource' }
  let(:version) { 'v3' }
  let(:template) { 'https://api.%<bounded_context>s.host.com/%<version>s/%<entity>s' }

  subject(:resolved_client) { described_class.call(context, entity, version, template: template) }

  it 'replaces the placeholders with the provided values' do
    expect(resolved_client.base_url).to eq 'https://api.context.host.com/v3/resource'
  end

  context 'with empty context' do
    let(:context) { '' }
    it 'removes duplicated dots in case of empty context' do
      expect(resolved_client.base_url).to eq 'https://api.host.com/v3/resource'
    end
  end

  %i[
    consultation
    pet_parent
    pet
  ].each do |resource|
    it "responds to #{resource}" do
      expect(described_class).to respond_to resource
    end
  end
end
