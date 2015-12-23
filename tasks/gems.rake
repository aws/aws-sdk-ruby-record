desc 'Builds the aws-record gem'
task 'gems:build' do
  sh("rm -f *.gem")
  sh("gem build aws-record.gemspec")
end

task 'gems:push' do
  sh("gem push aws-record-#{$VERSION}.gem")
end
