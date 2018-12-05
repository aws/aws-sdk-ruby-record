version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name          = "aws-record"
  spec.version       = version
  spec.authors       = ["Amazon Web Services"]
  spec.email         = ["alexwood@amazon.com"]
  spec.summary       = "AWS Record library for Amazon DynamoDB"
  spec.description   = "Provides an object mapping abstraction for Amazon DynamoDB."
  spec.homepage      = "http://github.com/aws/aws-sdk-ruby-record"
  spec.license       = "Apache 2.0"

  spec.require_paths = ["lib"]
  spec.files = Dir['lib/**/*.rb']

  spec.add_dependency('aws-sdk-dynamodb', '~> 1.18')
end
