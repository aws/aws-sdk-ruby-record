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

task 'test' => ['test:unit']
