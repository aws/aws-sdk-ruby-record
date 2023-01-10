# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
