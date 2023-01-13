# frozen_string_literal: true

require 'securerandom'
require 'aws-sdk-core'
require 'aws-record'

def cleanup_table
  begin
    log "Cleaning Up Table: #{@table_name}"
    @client.delete_table(table_name: @table_name)
    log "Cleaned up table: #{@table_name}"
    @table_name = nil
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    log "Cleanup: Table #{@table_name} doesn't exist, continuing."
    @table_name = nil
  rescue Aws::DynamoDB::Errors::ResourceInUseException => e
    log "Failed to delete table, waiting to retry."
    @client.wait_until(:table_exists, table_name: @table_name)
    sleep(10)
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

Then(/^calling "([^"]*)" on the model should return:$/) do |method, retval|
  expected = JSON.parse(retval, symbolize_names: true)
  expect(@model.send(method)).to eq(expected)
end

Given(/^an aws\-record model with definition:$/) do |string|
  @model = Class.new do
    include(Aws::Record)
  end
  @table_name ||= "test_table_#{SecureRandom.uuid}"
  @model.set_table_name(@table_name)
  @model.class_eval(string)
end

Then(/^the DynamoDB table should have exactly the following item attributes:$/) do |string|
  data = JSON.parse(string)
  key = {}
  data["key"].each do |row|
    attribute, value = row
    key[attribute] = value
  end
  resp = @client.get_item(
    table_name: @table_name,
    key: key
  )
  expect(resp.item.keys.sort).to eq(data["item"].keys.sort)
  data["item"].each do |k,v|
    expect(resp.item[k]).to eq(v)
  end
end
