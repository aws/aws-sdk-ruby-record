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

task 'github:require-access-token' do
  unless ENV['AWS_SDK_FOR_RUBY_GH_TOKEN']
    warn("export ENV['AWS_SDK_FOR_RUBY_GH_TOKEN']")
    exit
  end
end

# this task must be defined to deploy
task 'github:access-token'

task 'github:release' do
  require 'octokit'

  gh = Octokit::Client.new(access_token: ENV['AWS_SDK_FOR_RUBY_GH_TOKEN'])

  repo = 'aws/aws-record'
  tag_ref_sha = `git show-ref v#{$VERSION}`.split(' ').first
  tag = gh.tag(repo, tag_ref_sha)

  release = gh.create_release(repo, "v#{$VERSION}", {
    name: 'Release v' + $VERSION + ' - ' + tag.tagger.date.strftime('%Y-%m-%d'),
    body: tag.message.lines.to_a[2..-1].join,
    prerelease: $VERSION.match('rc') ? true : false,
  })

  gh.upload_asset(release.url, "aws-record-#{$VERSION}.gem",
    :content_type => 'application/octet-stream')

end

task 'github:access_token'
