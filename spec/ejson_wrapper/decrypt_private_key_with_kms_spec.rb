RSpec.describe EJSONWrapper::DecryptPrivateKeyWithKMS do
  let(:kms_client) { instance_double(Aws::KMS::Client) }
  let(:decrypt_response) { double(plaintext: private_key) }
  let(:private_key) { 'private-key' }
  let(:ejson_file) { '{ "_private_key_enc": "blah", "_public_key": "pubkey" }' }

  before do
    allow(Aws::KMS::Client).to receive(:new).and_return(kms_client)
    allow(kms_client).to receive(:decrypt).and_return(decrypt_response)
    allow(File).to receive(:read).with('config/secrets/test.ejson').and_return(ejson_file)
  end

  it 'decrypts with KMS' do
    described_class.call('config/secrets/test.ejson')
    expect(kms_client).to have_received(:decrypt).with(ciphertext_blob: Base64.decode64('blah'))
  end

  it 'returns the plaintext' do
    response = described_class.call('config/secrets/test.ejson')
    expect(response).to eq('private-key')
  end
end
