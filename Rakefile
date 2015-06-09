require "bundler/gem_tasks"
require "rspec/core/rake_task"

$REPO_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join($REPO_ROOT, 'lib'))

desc "aws-record unit tests"
RSpec::Core::RakeTask.new('test:unit') do |t|
  t.rspec_opts = "-I #{$REPO_ROOT}/lib"
  t.rspec_opts << " -I #{$REPO_ROOT}/spec"
  t.pattern = "#{$REPO_ROOT}/spec"
end

begin
  require 'cucumber/rake/task'
  desc = 'aws-record integration tests'
  Cucumber::Rake::Task.new('test:integration', desc) do |t|
    t.cucumber_opts = 'features -t ~@veryslow'
  end
rescue LoadError
  desc 'aws-record integration tests'
  task 'test:integration' do
    puts 'skipping integration tests, cucumber not loaded'
  end
end

task 'test' => ['test:unit', 'test:integration']
