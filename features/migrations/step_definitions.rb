# frozen_string_literal: true

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
  boolean = !(b == 'false' || b.nil?)
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
