RSpec.describe KB do
  it 'has a version number' do
    expect(KB::VERSION).not_to be nil
  end

  describe 'request timeouts configuration' do
    it 'defaults connect_timeout to 1' do
      expect(described_class.config.request.connect_timeout).to eq 1
    end

    it 'defaults write_timeout to 3' do
      expect(described_class.config.request.write_timeout).to eq 3
    end

    it 'defaults read_timeout to 5' do
      expect(described_class.config.request.read_timeout).to eq 5
    end

    it 'rejects the removed global timeout setting' do
      expect { described_class.config.request.timeout = 12 }.to raise_error(NoMethodError)
    end
  end
end
