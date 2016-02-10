require 'coveralls'
Coveralls.wear_merged!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])

SimpleCov.start do

  project_name 'AWS Record'

  add_filter '/spec/'
  add_filter '/features/'

  merge_timeout 60 * 15 # 15 minutes

end
