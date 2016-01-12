# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not
# use this file except in compliance with the License. A copy of the License is
# located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions
# and limitations under the License.

task 'release:require-version' do
  unless ENV['VERSION']
    warn("usage: VERSION=x.y.z rake release")
    exit
  end
end

# bumps the VERSION file
task 'release:bump-version' do
  sh("echo '#{$VERSION}' > VERSION")
  path = 'lib/aws-record/record/version.rb'
  file = File.read(path)
  file = file.gsub(/VERSION = '.+?'/, "VERSION = '#{$VERSION}'")
  File.open(path, 'w') { |f| f.write(file) }
  sh("git add #{path}")
  sh("git add VERSION")
end

# ensures all of the required credentials are present
task 'release:check' => [
  'release:require-version',
  'github:require-access-token',
  'git:require-clean-workspace',
]

# builds release artifacts
task 'release:build' => [
  'changelog:version',
  'release:bump-version',
  'git:tag',
  'gems:build'
]

# deploys release artifacts
task 'release:publish' => [
  'release:require-version',
  'git:push',
  'gems:push',
  'github:release',
]

# post release tasks
task 'release:cleanup' => [
  'changelog:next_release',
]

desc "Public release, `VERSION=x.y.z rake release`"
task :release => [
  'release:check',
  'test',
  'release:build',
  'release:publish',
  'release:cleanup'
]
