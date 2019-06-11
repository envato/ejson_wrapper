# EJSON Wrapper

Wraps the [`ejson`](https://github.com/Shopify/ejson) program to safely execute it and parse the resulting JSON. Additionally it offers a feature to encrypt/decrypt private key with AWS KMS (stored as `_private_key_enc` in EJSON file).

## Prerequisites

* [`ejson`](https://github.com/Shopify/ejson) application
* Path to `ejson` binary is included in `PATH` environment variable

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ejson_wrapper'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install ejson_wrapper
```

## Usage

### Decrypting EJSON files

Ensure your application has [AWS IAM Permission to decrypt with KMS](https://docs.aws.amazon.com/kms/latest/developerguide/iam-policies.html#iam-policy-example-encrypt-decrypt-specific-cmks).

In Ruby code:

```
# Private key is in /opt/ejson/keys
EJSONWrapper.decrypt('myfile.ejson')
=> { :my_api_key => 'secret' }

# Private key is in /alternate/key/dir
EJSONWrapper.decrypt('myfile.ejson', key_dir: 'alternate/key/dir')
=> { :my_api_key => 'secret' }

# Private key is in memory
EJSONWrapper.decrypt('myfile.ejson', private_key: 'be8597abaa68bbfa23193624b1ed5e2cd6b9a8015e722138b23ecd3c90239b2d')
=> { :my_api_key => 'secret' }

# Private key is stored inside the ejson file itself as _private_key_enc (encrypted with KMS & Base64 encoded)
EJSONWrapper.decrypt('myfile.ejson', use_kms: true, region: 'ap-southeast-2')
=> { :my_api_key => 'secret' }
```

Command line:

```
# decrypt all
$ ejson_wrapper decrypt --file file.ejson --region us-east-1
{
  "my_api_key": "[secret]"
}

# decrypt & extract a specific secret
$ ejson_wrapper decrypt --file file.ejson --region us-east-1 --secret my_api_key
[secret]
```

### Generating EJSON files

Ensure your application has [AWS IAM Permission to encrypt with KMS](https://docs.aws.amazon.com/kms/latest/developerguide/iam-policies.html#iam-policy-example-encrypt-decrypt-specific-cmks).

Firstly, the EJSON is generated to have public key and Base64 encoded & encrypted private key in `_public_key` and `_private_key_enc` respectively with:

Using CLI:

```
$ ejson_wrapper generate --region $AWS_REGION --kms-key-id [key_id] --file myfile.ejson
Generated EJSON file myfile.ejson
```

OR Ruby code:

```
# Generate encrypted EJSON file (overwritting the unencrypted EJSON file)
EJSONWrapper.generate(region: ENV['AWS_REGION'], kms_key_id: 'key_id', file: 'myfile.ejson')
=> Generated EJSON file myfile.ejson
```

Verify to ensure the new file contain the two required keys:

```
$ cat myfile.ejson
{
  "_public_key": "[public_key]",
  "_private_key_enc":"[base64_encoded_encrypted_private_key]",
}
```

You now can add secrets into the EJSON file, in following example `my_api_key` in plaintext entry is added:

``
# myfile.ejson
{
  "_public_key": "[public_key]",
  "_private_key_enc":"[base64_encoded_encrypted_private_key]",
  "my_api_key": "plaintext"
}
``

to encrypt the secrets, run following command:

```
$ ejson encrypt myfile.ejson
```

Verify to ensure the secret is encrypted correctly:

```
$ cat myfile.ejson
{
  "_public_key": "[public_key]",
  "_private_key_enc":"[base64_encoded_encrypted_private_key]",
  "my_api_key": "encrypted_secret"
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/envato/ejson_wrapper.
