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
    h = item.to_h
    expect(expected.any? { |e| h == e }).to eq(true)
  end
end

When(/^we call the 'scan' class method$/) do
  @collection = @model.scan
end

When(/^we take the first member of the result collection$/) do
  @instance = @collection.first
end
