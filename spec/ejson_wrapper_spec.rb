RSpec.describe EJSONWrapper do
  let(:private_key) { 'be8597abaa68bbfa23193624b1ed5e2cd6b9a8015e722138b23ecd3c90239b2d' }
  let(:public_key) { '4f541845020de031e09a40910d10e2f731fe8d555808158fb36b343ad3619f72' }
  let(:encrypted_secret) { 'EJ[1:eenrVkocrCrgrLobF0K/YSqMt0CAg/bHgGtnX7VWh2M=:OxDHz5edtlVj2C8EHRvVU3O0JSsKvfNB:PbECFxlvBHs943P1U8rkXsiEBCVD]' }
  let(:ejson_tempfile) { Tempfile.new('ejson') }
  let(:ejson_contents) { %'{"_public_key":"#{public_key}","secret":"#{encrypted_secret}"}' }

  def decrypt(file_path, **args)
    EJSONWrapper.decrypt(file_path, **args)
  end

  context "when the ejson file doesn't exist" do
    it 'raises an error' do
      expect { decrypt('/tmp/unkown_blah_123909u2309') }.to raise_error(EJSONWrapper::DecryptionFailed)
    end
  end

  context 'when the ejson file exists' do
    before do
      ejson_tempfile.write(ejson_contents)
      ejson_tempfile.close
    end

    it 'decrypts the file given a keydir with the private key' do
      Dir.mktmpdir do |key_dir|
        File.write(File.join(key_dir, public_key), private_key)
        decrypted_secrets = decrypt(ejson_tempfile.path, key_dir: key_dir)
        expect(decrypted_secrets[:secret]).to eq 'sssh!'
      end
    end

    it 'decrypts given a private key argument' do
      decrypted_secrets = decrypt(ejson_tempfile.path, private_key: private_key)
      expect(decrypted_secrets[:secret]).to eq 'sssh!'
    end

    it "doesn't include _public_key or _private_key_enc in the decrypted secrets" do
      decrypted_secrets = decrypt(ejson_tempfile.path, private_key: private_key)
      expect(decrypted_secrets.key?(:_public_key)).to eq false
      expect(decrypted_secrets.key?(:_private_key_enc)).to eq false
    end

    it "doesn't supply a key dir env var when it's not supplied as an argument" do
      decrypted_secrets = '{"api_key_1": "my-secret-api-key"}'
      allow(Open3).to receive(:capture2).and_return([decrypted_secrets, double(success?: true)])
      decrypt(ejson_tempfile.path)
      expect(Open3).to have_received(:capture2).with({}, 'ejson', 'decrypt', ejson_tempfile.path, {})
    end

    context 'when the ejson file has a _private_key_enc key and use_kms: true' do
      let(:ejson_contents) { %'{"_public_key":"#{public_key}","secret":"#{encrypted_secret}", "_private_key_enc": "#{private_key_enc}"}' }
      let(:private_key_enc) { "priv-key-enc" }

      before do
        client = instance_double(Aws::KMS::Client)
        allow(Aws::KMS::Client).to receive(:new).and_return(client)
        response = double(plaintext: private_key)
        allow(client).to receive(:decrypt).with(ciphertext_blob: Base64.decode64(private_key_enc)).and_return(response)
      end

      it 'decrypts with KMS' do
        decrypted_secrets = decrypt(ejson_tempfile.path, use_kms: true)
        expect(decrypted_secrets[:secret]).to eq 'sssh!'
      end
    end

    context 'when the stdout of ejson contains invalid JSON' do
      let(:decrypted_secrets) { '{"api_key_1": "my-secret-api-key", "' }

      before do
        allow(Open3).to receive(:capture2).and_return([decrypted_secrets, double(success?: true)])
      end

      it "doesn't throw an error with the contents of the decrypted JSON" do
        expect { decrypt(ejson_tempfile.path) }.to raise_error { |error|
          expect(error.message).to_not include('my-secret-api-key')
        }
      end

      it 'throws a decryption failed error' do
        expect {
          decrypt(ejson_tempfile.path)
        }.to raise_error(EJSONWrapper::DecryptionFailed, /Failed to parse/)
      end
    end
  end
end
