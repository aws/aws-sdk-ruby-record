# Aws::Record

A data mapping abstraction over the AWS SDK for Ruby's client for Amazon
DynamoDB.

This library is currently under development. More features will be added as we
approach general availability, and while our initial release has as small of an
API surface area as possible, the interface may change before the GA release.

We would like to invite you to be a part of the ongoing development of this gem.
We welcome your contributions, and would also be happy to hear from you about
how you would like to use this gem. Feature requests are welcome.

## Installation

`Aws::Record` is available as the `aws-record` gem from RubyGems.

```
gem install 'aws-record' --pre
```

Please use a major version when expressing a dependency on `aws-record`.

```ruby
gem 'aws-record', '~> 1.0'
```

Until the final release becomes available on Rubygems, leave off the version
dependency in your Gemfile so Bundler can find it.

## Usage

To create a model that uses `aws-record` features, simply include the provided
module:

```ruby
class MyModel
  include Aws::Record
end
```

You can then specify attributes using the `aws-record` DSL:

```ruby
class MyModel
  include Aws::Record
  integer_attr :id, hash_key: true
  string_attr  :name, range_key: true
  boolean_attr :active, database_attribute_name: "is_active_flag"
end
```

If a matching table does not exist in DynamoDB, you can use table migrations to
create your table.

```ruby
migration = Aws::Record::TableMigration.new(MyModel)
migration.create!(
  provisioned_throughput: {
    read_capacity_units: 5,
    write_capacity_units: 2
  }
)
migration.wait_until_available
```

With a table in place, you can then use your model class to manipulate items in
your table:

```ruby
item = MyModel.find(id: 1, name: "Hello Record")
item.active = true
item.save
item.delete!

MyModel.find(id: 1, name: "Hello Record") # => nil

item = MyModel.new
item.id = 2
item.name = "Item"
item.active = false
item.save
```
