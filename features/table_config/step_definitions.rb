# Copyright 2015-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

Given(/^a TableConfig of:$/) do |code_block|
  TableConfigTestModel = @model
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
