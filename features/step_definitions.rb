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

require 'securerandom'
require 'aws-sdk-core'
require 'aws-record'

def cleanup_table
  begin
    @client.delete_table(table_name: @table_name)
    puts "Cleaned up table: #{@table_name}"
    @table_name = nil
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    puts "Cleanup: Table #{@table_name} doesn't exist, continuing."
    @table_name = nil
  rescue Aws::DynamoDB::Errors::ResourceInUseException => e
    @client.wait_until(:table_exists, table_name: @table_name)
    retry
  end
end

Before do
  @client = Aws::DynamoDB::Client.new(region: "us-east-1")
end

After("@dynamodb") do
  cleanup_table
end

Given(/^a DynamoDB table named '([^"]*)' with data:$/) do |table, string|
  data = JSON.parse(string)
  @table_name = "#{table}_#{SecureRandom.uuid}"
  attr_def = data.inject([]) do |acc, row|
    acc << {
      attribute_name: row['attribute_name'],
      attribute_type: row['attribute_type']
    }
  end
  key_schema = data.inject([]) do |acc, row|
    acc << {
      attribute_name: row['attribute_name'],
      key_type: row['key_type']
    }
  end
  @client.create_table(
    table_name: @table_name,
    attribute_definitions: attr_def,
    key_schema: key_schema,
    provisioned_throughput: {
      read_capacity_units: 1,
      write_capacity_units: 1
    }
  )
  @client.wait_until(:table_exists, table_name: @table_name) do |w|
    w.delay = 5
    w.max_attempts = 25
  end
end

Given(/^an aws\-record model with data:$/) do |string|
  data = JSON.parse(string)
  @model = Class.new do
    include(Aws::Record)
  end
  @model.configure_client(client: @client)
  @table_name ||= "test_table_#{SecureRandom.uuid}"
  @model.set_table_name(@table_name)
  data.each do |row|
    opts = {}
    opts[:database_attribute_name] = row['database_name']
    opts[:hash_key] = row['hash_key']
    opts[:range_key] = row['range_key']
    @model.send(:"#{row['method']}", row['name'].to_sym, opts)
  end
end

When(/^we create a new instance of the model with attribute value pairs:$/) do |string|
  data = JSON.parse(string)
  @instance = @model.new
  data.each do |row|
    attribute, value = row
    @instance.send(:"#{attribute}=", value)
  end
end

When(/^we save the model instance$/) do
  @instance.save
end

Then(/^the DynamoDB table should have an object with key values:$/) do |string|
  data = JSON.parse(string)
  key = {}
  data.each do |row|
    attribute, value = row
    key[attribute] = value
  end
  resp = @client.get_item(
    table_name: @table_name,
    key: key
  )
  expect(resp.item).not_to eq(nil)
end

Given(/^an item exists in the DynamoDB table with item data:$/) do |string|
  data = JSON.parse(string)
  @client.put_item(
    table_name: @table_name,
    item: data
  )
end

When(/^we call the 'find' class method with parameter data:$/) do |string|
  data = JSON.parse(string, symbolize_names: true)
  @instance = @model.find(data)
end

Then(/^we should receive an aws\-record item with attribute data:$/) do |string|
  data = JSON.parse(string, symbolize_names: true)
  data.each do |key, value|
    expect(@instance.send(key)).to eq(value)
  end
end

When(/^we call 'delete!' on the aws\-record item instance$/) do
  @instance.delete!
end

Then(/^the DynamoDB table should not have an object with key values:$/) do |string|
  data = JSON.parse(string)
  key = {}
  data.each do |row|
    attribute, value = row
    key[attribute] = value
  end
  resp = @client.get_item(
    table_name: @table_name,
    key: key
  )
  expect(resp.item).to eq(nil)
end

When(/^we create a table migration for the model$/) do
  @migration = Aws::Record::TableMigration.new(@model, client: @client)
end

When(/^we call 'create!' with parameters:$/) do |string|
  data = JSON.parse(string, symbolize_names: true)
  @migration.create!(data)
end

Then(/^eventually the table should exist in DynamoDB$/) do
  @client.wait_until(:table_exists, table_name: @table_name) do |w|
    w.delay = 5
    w.max_attempts = 25
  end
  true
end

Then(/^calling 'table_exists\?' on the model should return "([^"]*)"$/) do |b|
  boolean = b == "false" || b.nil? ? false : true
  expect(@model.table_exists?).to eq(boolean)
end

When(/^we call 'delete!' on the migration$/) do
  @migration.delete!
end

Then(/^eventually the table should not exist in DynamoDB$/) do
  @client.wait_until(:table_not_exists, table_name: @table_name) do |w|
    w.delay = 5
    w.max_attempts = 25
  end
end

When(/^we call 'wait_until_available' on the migration$/) do
  @migration.wait_until_available
end

When(/^we call 'update!' on the migration with parameters:$/) do |string|
  data = JSON.parse(string, symbolize_names: true)
  @migration.update!(data)
  # Wait until table is active again before proceeding.
  @client.wait_until(:table_exists, table_name: @table_name) do |w|
    w.delay = 5
    w.max_attempts = 25
  end
end

Then(/^calling "([^"]*)" on the model should return:$/) do |method, retval|
  expected = JSON.parse(retval, symbolize_names: true)
  expect(@model.send(method)).to eq(expected)
end

When(/^we call the 'query' class method with parameter data:$/) do |string|
  data = JSON.parse(string, symbolize_names: true)
  @collection = @model.query(data)
end

Then(/^we should receive an aws\-record collection with members:$/) do |string|
  expected = JSON.parse(string, symbolize_names: true)
  # Ensure that we have the same number of items, and no pagination.
  expect(expected.size).to eq(@collection.to_a.size)
  # Results do not have guaranteed order, check each expected value individually
  @collection.each do |item|
    h = {
      id: item.id,
      count: item.count,
      content: item.body # Because of database special name.
    }
    expect(expected.any? { |expect| h == expect }).to eq(true)
  end
end

When(/^we call the 'scan' class method$/) do
  @collection = @model.scan
end

Given(/^an aws\-record model with definition:$/) do |string|
  @model = Class.new do
    include(Aws::Record)
  end
  @table_name ||= "test_table_#{SecureRandom.uuid}"
  @model.set_table_name(@table_name)
  @model.class_eval(string)
end

When(/^we add a local secondary index to the model with parameters:$/) do |string|
  name, hash = JSON.parse(string, symbolize_names: true)
  name = name.to_sym
  hash[:range_key] = hash[:range_key].to_sym
  @model.local_secondary_index(name, hash)
end

Then(/^the table should have a local secondary index named "([^"]*)"$/) do |expected|
  resp = @client.describe_table(table_name: @table_name)
  lsis = resp.table.local_secondary_indexes
  exists = lsis && lsis.any? { |index| index.index_name == expected }
  expect(exists).to eq(true)
end

When(/^we add a global secondary index to the model with parameters:$/) do |string|
  name, hash = JSON.parse(string, symbolize_names: true)
  name = name.to_sym
  hash[:hash_key] = hash[:hash_key].to_sym
  hash[:range_key] = hash[:range_key].to_sym
  @model.global_secondary_index(name, hash)
end

Then(/^the table should have a global secondary index named "([^"]*)"$/) do |expected|
  resp = @client.describe_table(table_name: @table_name)
  gsis = resp.table.global_secondary_indexes
  exists = gsis && gsis.any? { |index| index.index_name == expected }
  expect(exists).to eq(true)
end
