RSpec.describe EJSONWrapper::Generate do
  let(:kms_client) { instance_double(Aws::KMS::Client) }
  let(:key_id) { 'key-id' }
  let(:file) { 'file.ejson' }
  let(:private_key_enc) { 'kms-encrypted-private-key' }
  let(:encrypt_response) { double(ciphertext_blob: private_key_enc) }
  let(:public_key) { '8ea2fbfb3291284dbcb1d5c7de5ff89dc51ffab896e791ca090493fb784f2a58' }
  let(:private_key) { 'e41d030042d4bae253a496129ba0f489b1db824d457b633d987022bc852efc04' }
  let(:ejson_keygen) {
  <<-EOS
Public Key:
#{public_key}
Private Key:
#{private_key}
EOS
  }

  before do
    allow(File).to receive(:write)
    allow(Aws::KMS::Client).to receive(:new).and_return(kms_client)
    allow(kms_client).to receive(:encrypt).and_return(encrypt_response)
    allow(Open3).to receive(:capture2e).with('ejson', 'keygen').and_return([ejson_keygen, double(:'success?' => true)])
    described_class.new.call(region: 'ap-southeast-2', kms_key_id: key_id, file: file)
  end

  it 'encrypts the private key' do
    expect(kms_client).to have_received(:encrypt).with(key_id: key_id, plaintext: private_key)
  end

  it 'writes an ejson file' do
    ejson = {
      '_public_key' => public_key,
      '_private_key_enc' => Base64.encode64(private_key_enc).strip
    }
    expect(File).to have_received(:write).with(file, JSON.pretty_generate(ejson))
  end
end
