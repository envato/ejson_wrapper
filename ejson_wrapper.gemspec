# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ejson_wrapper/version"

Gem::Specification.new do |spec|
  spec.name          = "ejson_wrapper"
  spec.version       = EjsonWrapper::VERSION
  spec.authors       = ["Steve Hodgkiss"]
  spec.email         = ["steve@hodgkiss.me"]

  spec.summary       = %q{Invoke EJSON from Ruby}
  spec.description   = %q{Invoke EJSON from Ruby}
  spec.homepage      = "https://github.com/envato/ejson_wrapper"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ejson"
  spec.add_dependency "aws-sdk-kms"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
