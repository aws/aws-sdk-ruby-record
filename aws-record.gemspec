# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "aws-record"
  spec.version       = File.read(File.expand_path('../VERSION', __FILE__)).strip
  spec.authors       = ["Amazon Web Services"]
  spec.email         = ["mamuller@amazon.com", "alexwoo@amazon.com"]
  spec.summary       = "AWS Record library for Amazon DynamoDB"
  spec.description   = "Provides an object mapping abstraction for Amazon DynamoDB."
  spec.homepage      = "https://github.com/aws/aws-sdk-ruby-record"
  spec.license       = "Apache 2.0"

  spec.require_paths = ["lib"]
  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'CHANGELOG.md', 'VERSION']

  spec.add_dependency('aws-sdk-dynamodb', '~> 1.18')
end
