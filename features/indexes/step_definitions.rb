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
