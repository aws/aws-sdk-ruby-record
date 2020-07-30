source 'https://rubygems.org'

# Specify your gem's dependencies in aws-record.gemspec
gemspec

gem 'rake', require: false

group :test do
  gem 'rspec'
  gem 'cucumber'
  
  gem 'simplecov', require: false
  # for simplecov on ruby 1.9
  gem 'json', '2.1.0'

  if ENV["NEW_RAILS"]
    gem 'activemodel'
  else
    gem 'activemodel', '< 5.0'
  end
end

group :docs do
  gem 'yard'
  gem 'yard-sitemap', '~> 1.0'
end

group :release do
  gem 'octokit'
end
