require "ejson_wrapper/version"
require "ejson_wrapper/decrypt_private_key_with_kms"
require "ejson_wrapper/decrypt_ejson_file"
require "ejson_wrapper/generate"

module EJSONWrapper
  def self.decrypt(file_path, key_dir: nil, private_key: nil, use_kms: false, region: nil)
    if use_kms
      private_key = private_key_decrypted(file_path, region: region)
    end
    DecryptEJSONFile.call(file_path, key_dir: key_dir, private_key: private_key)
  end

  def self.generate(**args)
    Generate.new.call(**args)
  end

  def self.private_key_decrypted(file_path, region: nil)
    DecryptPrivateKeyWithKMS.call(file_path, region: region)
  end
end
