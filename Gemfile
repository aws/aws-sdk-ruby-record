source 'https://rubygems.org'

gemspec

gem 'rake', require: false

group :test do
  gem 'rspec'
  gem 'cucumber'
  
  gem 'simplecov', require: false

  if RUBY_VERSION >= '3.0'
    gem 'rexml'
  end

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

group :development do
  # rubocop's TargetRubyVersion is 2.0.0
  # Ruby version required less than 3.0
  # gem 'rubocop', '0.50.0'
end
