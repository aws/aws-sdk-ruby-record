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
