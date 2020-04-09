
desc 'Set aws-record specific doc settings'
task 'docs:setup_env' do
  ENV['SOURCE'] = '1'
  ENV['SITEMAP_BASEURL'] = 'http://docs.aws.amazon.com/awssdkrubyrecord/api/'
end