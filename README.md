# Aws::Record

[![Build Status](https://travis-ci.org/aws/aws-sdk-ruby-record.svg?branch=main)](https://travis-ci.org/aws/aws-sdk-ruby-record) [![Code Climate](https://codeclimate.com/github/aws/aws-sdk-ruby-record.svg)](https://codeclimate.com/github/aws/aws-sdk-ruby-record) [![Coverage Status](https://coveralls.io/repos/github/aws/aws-sdk-ruby-record/badge.svg?branch=main)](https://coveralls.io/github/aws/aws-sdk-ruby-record?branch=main)

A data mapping abstraction over the AWS SDK for Ruby's client for Amazon
DynamoDB.

This library is currently under development. More features will be added as we
approach general availability, and while our initial release has as small of an
API surface area as possible, the interface may change before the GA release.

We would like to invite you to be a part of the ongoing development of this gem.
We welcome your contributions, and would also be happy to hear from you about
how you would like to use this gem. Feature requests are welcome.

## Links of Interest

* [Documentation](http://docs.aws.amazon.com/awssdkrubyrecord/api/)
* [Change Log](https://github.com/aws/aws-sdk-ruby-record/blob/main/CHANGELOG.md)
* [Issues](https://github.com/aws/aws-sdk-ruby-record/issues)
* [License](http://aws.amazon.com/apache2.0/)

## Installation

`Aws::Record` is available as the `aws-record` gem from RubyGems.

```shell
gem install 'aws-record'
```

```ruby
gem 'aws-record', '~> 2.0'
```

This automatically includes a dependency on the `aws-sdk-dynamodb` gem (part of the modular version-3 of 
the [AWS SDK for Ruby](https://aws.amazon.com/sdk-for-ruby/). If you need to pin to a specific version, 
you can add [aws-sdk-dynamodb](https://rubygems.org/gems/aws-sdk-dynamodb) 
or [aws-sdk-core](https://rubygems.org/gems/aws-sdk-core) gem in your
Gemfile.

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

If a matching table does not exist in DynamoDB, you can use the TableConfig DSL to create your table:

```ruby
cfg = Aws::Record::TableConfig.define do |t|
  t.model_class(MyModel)
  t.read_capacity_units(5)
  t.write_capacity_units(2)
end
cfg.migrate!
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

### Inheritance Support
Aws Record models can be extended using standard ruby inheritance. The child model must 
include `Aws::Record` in their model and the following will be inherited:
* [set_table_name](https://docs.aws.amazon.com/sdk-for-ruby/aws-record/api/Aws/Record/RecordClassMethods.html#set_table_name-instance_method)
* [Attributes and Keys](https://docs.aws.amazon.com/sdk-for-ruby/aws-record/api/Aws/Record/Attributes.html#initialize-instance_method)
* Mutation Tracking:
  * [enable_mutation_tracking](https://docs.aws.amazon.com/sdk-for-ruby/aws-record/api/Aws/Record/RecordClassMethods.html#enable_mutation_tracking-instance_method)
  * [disable_mutation_tracking](https://docs.aws.amazon.com/sdk-for-ruby/aws-record/api/Aws/Record/RecordClassMethods.html#disable_mutation_tracking-instance_method)
* [local_secondary_indexes](https://docs.aws.amazon.com/sdk-for-ruby/aws-record/api/Aws/Record/SecondaryIndexes/SecondaryIndexesClassMethods.html#local_secondary_indexes-instance_method)
* [global_secondary_indexes](https://docs.aws.amazon.com/sdk-for-ruby/aws-record/api/Aws/Record/SecondaryIndexes/SecondaryIndexesClassMethods.html#global_secondary_indexes-instance_method)
* [configure_client](https://docs.aws.amazon.com/sdk-for-ruby/aws-record/api/Aws/Record/ClientConfiguration.html#configure_client-instance_method)

See example below to see the feature in action.

```ruby
class Animal
  include Aws::Record
  string_attr :name, hash_key: true
  integer_attr :age
end

class Dog < Animal
  include Aws::Record
  boolean_attr :family_friendly
end

dog = Dog.find(name: 'Sunflower')
dog.age = 3
dog.family_friendly = true
```