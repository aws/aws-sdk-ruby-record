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

task 'changelog:version' do
  # replaces "Next Release (TBD)" in the CHANGELOG with a version and date
  changelog = File.open('CHANGELOG.md', 'r', encoding: 'UTF-8') { |f| f.read }
  changelog = changelog.lines.to_a
  changelog[0] = "#{$VERSION} (#{Time.now.strftime('%Y-%m-%d')})\n"
  changelog = changelog.join
  File.open('CHANGELOG.md', 'w', encoding: 'UTF-8') { |f| f.write(changelog) }
  sh("git add CHANGELOG.md")
end

task 'changelog:next_release' do
  # inserts a "Next Release (TDB)" section at the top of the CHANGELOG
  lines = []
  lines << "Unreleased Changes\n"
  lines << "------------------\n"
  lines << "\n"
  changelog = File.open('CHANGELOG.md', 'r', encoding: 'UTF-8') { |f| f.read }
  changelog = lines.join + changelog
  File.open('CHANGELOG.md', 'w', encoding: 'UTF-8') { |f| f.write(changelog) }
  sh("git add CHANGELOG.md")
  sh("git commit -m 'Added next release section to the changelog. [ci skip]'")
end

task 'changelog:latest' do
  # Returns the contents of the most recent CHANGELOG section
  changelog = File.open('CHANGELOG.md', 'r', encoding: 'UTF-8') { |f| f.read }
  lines = []
  changelog.lines.to_a[3..-1].each do |line|
    if line.match(/^\d+\.\d+\.\d+/)
      break
    else
      lines << line
    end
  end
  puts lines[0..-2].join
end
