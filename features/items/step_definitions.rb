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

When(/^we create a new instance of the model with attribute value pairs:$/) do |string|
  data = JSON.parse(string)
  @instance = @model.new
  data.each do |row|
    attribute, value = row
    @instance.send(:"#{attribute}=", value)
  end
end

When(/^we save the model instance$/) do
  @save_output = @instance.save
end

When(/^we call the 'find' class method with parameter data:$/) do |string|
  data = JSON.parse(string, symbolize_names: true)
  @instance = @model.find(data)
end

When(/^we call the 'update' class method with parameter data:$/) do |string|
  data = JSON.parse(string, symbolize_names: true)
  @model.update(data)
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

When(/^we call 'update' on the aws\-record item instance with parameter data:$/) do |string|
  data = JSON.parse(string, symbolize_names: true)
  @instance.update(data)
end

When(/^we set the item attribute "([^"]*)" to be "([^"]*)"$/) do |attr, value|
  @instance.send(:"#{attr}=", value)
end

Then(/^calling save should raise a conditional save exception$/) do
  expect { @instance.save }.to raise_error(
    Aws::Record::Errors::ConditionalWriteFailed
  )
end

When(/^we apply the following keys and values to map attribute "([^"]*)":$/) do |attribute, map_block|
  # This code will explode, probably with a NoMethodError, if you put in a
  # non-map attribute. It also intentionally uses mutation over assignment.
  value = @instance.send(:"#{attribute}")
  map = eval(map_block)
  value.merge!(map)
end

Then(/^the attribute "([^"]*)" on the item should match:$/) do |attribute, value_block|
  expected = eval(value_block)
  actual = @instance.send(:"#{attribute}")
  expect(actual).to eq(expected)
end

When(/^we call "([^"]*)" on aws\-record item instance with a value of "([^"]*)"$/) do |method, value|
  @instance.send(method, value.to_i)
end