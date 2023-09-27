# frozen_string_literal: true

require 'rspec/core/rake_task'

$REPO_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join($REPO_ROOT, 'lib'))
$VERSION = ENV['VERSION'] || File.read(File.join($REPO_ROOT, 'VERSION')).strip

task 'test:coverage:clear' do
  sh("rm -rf #{File.join($REPO_ROOT, 'coverage')}")
end

desc 'run unit tests'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = "-I #{$REPO_ROOT}/lib -I #{$REPO_ROOT}/spec"
  t.pattern = "#{$REPO_ROOT}/spec"
end
task spec: 'test:coverage:clear'
task 'test:unit' => :spec # alias old names

task 'cucumber' do
  exec('bundle exec cucumber')
end

# Ensure the test:integration task behaves as it always has
desc 'run integration tests'
task 'test:integration' do |_t|
  if ENV['AWS_INTEGRATION']
    Rake::Task['cucumber'].invoke
  else
    puts 'Skipping integration tests'
    puts 'export AWS_INTEGRATION=1 to enable integration tests'
  end
end

# Setup alias for old task names
task 'test:unit' => :spec
task test: %w[test:unit test:integration]
task default: :test

task 'release:test' => :spec

Dir.glob('**/*.rake').each do |task_file|
  load task_file
end
