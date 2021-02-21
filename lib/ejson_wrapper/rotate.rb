require 'open3'

module EJSONWrapper

  class Rotate
    def call(ejson_file, region, kms_key_id, create_key)
      decrypted = EJSONWrapper.decrypt(ejson_file, use_kms: true, region: region)
      if create_key
        kms_key_id = rotate_symmetric_key(region)
      end
      STDOUT.puts "Using the kms key #{kms_key_id}"
      new_ejson_file = "temp.ejson"
      EJSONWrapper.generate(region: region, kms_key_id: kms_key_id, file: new_ejson_file)
      new_ejson = JSON.parse(File.read(new_ejson_file)).merge(decrypted)
      File.open(new_ejson_file,"w") do |f|
        f.puts JSON.pretty_generate(new_ejson)
      end
      cmd = ['ejson', 'encrypt', new_ejson_file]
      stdout, status = Open3.capture2e(*cmd)
      if !status.success? then
        STDERR.puts "Encrypting failed: #{status} #{stdout}. Not replacing old file"
      else
        STDOUT.puts "Encryption succeeded for #{new_ejson_file}. Replacing old file"
        File.delete(ejson_file)
        File.rename(new_ejson_file, ejson_file)
      end
    end

    private

    def rotate_symmetric_key(region)
      kms_client = Aws::KMS::Client.new(region: region)
      new_kms_key = kms_client.create_key
      new_kms_key.key_metadata.key_id
    end
  end
end
