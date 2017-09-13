require 'open3'

module EJSONWrapper
  DecryptionFailed = Class.new(StandardError)

  class DecryptEJSONFile
    def self.call(file_path, **args)
      new.call(file_path, **args)
    end

    def call(file_path, key_dir: nil, private_key: nil)
      decrypted_json = invoke_decrypt(file_path, key_dir: key_dir, private_key: private_key)
      parse_json(decrypted_json)
    end

    private

    def invoke_decrypt(file_path, key_dir:, private_key:)
      command = ['ejson', 'decrypt']
      options = {}
      if private_key
        options[:stdin_data] = private_key
        command << '--key-from-stdin'
      end
      command << file_path.to_s
      stdout, status = Open3.capture2(ejson_env(key_dir), *command, options)
      raise DecryptionFailed, stdout unless status.success?
      stdout
    end

    def ejson_env(key_dir)
      {
        'EJSON_KEYDIR' => key_dir
      }.select { |v| !v.nil? }
    end

    def parse_json(decrypted_json)
      JSON.parse(decrypted_json, symbolize_names: true).tap do |secrets|
        secrets.delete(:_public_key)
        secrets.delete(:_private_key_enc)
      end.freeze
    rescue JSON::ParserError
      raise DecryptionFailed, "Failed to parse JSON output from EJSON"
    end
  end
end
