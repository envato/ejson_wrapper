require "ejson_wrapper/version"
require "ejson_wrapper/decrypt_private_key_with_kms"
require "ejson_wrapper/decrypt_ejson_file"

module EJSONWrapper
  def self.decrypt(file_path, key_dir: nil, private_key: nil, use_kms: false)
    if use_kms
      private_key = DecryptPrivateKeyWithKMS.call(file_path)
    end
    DecryptEJSONFile.call(file_path, key_dir: key_dir, private_key: private_key)
  end
end
