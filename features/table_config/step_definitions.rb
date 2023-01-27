# frozen_string_literal: true

Given(/^a TableConfig of:$/) do |code_block|
  TableConfigTestModel = @model # rubocop:disable Naming/ConstantName
  @table_config = eval(code_block)
end

When(/^we migrate the TableConfig$/) do
  @table_config.migrate!
end

Then(/^the TableConfig should be compatible with the remote table$/) do
  expect(@table_config.compatible?).to be_truthy
end

Then(/^the TableConfig should be an exact match with the remote table$/) do
  expect(@table_config.exact_match?).to be_truthy
end

Then(/^the TableConfig should not be compatible with the remote table$/) do
  expect(@table_config.compatible?).to be_falsy
end

Given(/^we add a global secondary index to the model with definition:$/) do |gsi|
  index_name, opts = eval(gsi)
  @model.global_secondary_index(index_name, opts)
end
