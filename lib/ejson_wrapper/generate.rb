require 'open3'
require 'aws-sdk-kms'

module EJSONWrapper
  KeygenFailed = Class.new(StandardError)

  class Generate
    def call(region:, kms_key_id:, file:)
      public_key, private_key = *keygen
      encrypted_private_key = encrypt_with_kms_key(region, kms_key_id, private_key)
      ejson_file = JSON.pretty_generate(
        '_public_key' => public_key,
        '_private_key_enc' => encrypted_private_key
      )
      File.write(file, ejson_file)
      puts "Generated EJSON file #{file}"
    end

    private

    def keygen
      output = invoke_ejson_keygen
      extract_keys(output)
    end

    def invoke_ejson_keygen
      stdout, status = Open3.capture2e('ejson', 'keygen')
      raise KeygenFailed, stdout unless status.success?
      stdout
    end

    def extract_keys(output)
      lines = output.split("\n")
      [lines[1], lines[3]]
    end

    def encrypt_with_kms_key(region, key_id, plaintext)
      client = Aws::KMS::Client.new(region: region)
      response = client.encrypt(
        key_id: key_id,
        plaintext: plaintext
      )
      Base64.encode64(response.ciphertext_blob).strip
    end
  end
end
