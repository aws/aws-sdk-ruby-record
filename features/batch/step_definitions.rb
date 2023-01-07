# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

And(/^a (Parent|Child) model with TableConfig of:$/) do |model, code_block|
  case model
  when 'Parent'
    ParentTableModel = @parent
  when 'Child'
    ChildTableModel = @model
  else
    raise 'Model must be either a Parent or Child'
  end

  @table_config = eval(code_block)
end

When(/^we make a batch write call with following Parent and Child model items:$/) do |string|
  item_data = JSON.parse(string, symbolize_names: true)

  Aws::Record::Batch.write do |db|
    item_data.each do |item|
      case item[:model]
      when 'Parent'
        formatted_item = remove_model_key(item)
        item_instance = @parent.new(formatted_item)
      when 'Child'
        formatted_item = remove_model_key(item)
        item_instance = @model.new(formatted_item)
      else
        raise 'Model must be either a Parent or Child'
      end
      db.put(item_instance)
    end
  end
end

And(/^we make a batch read call for the following Parent and Child model item keys:$/) do |string|
  key_batch = JSON.parse(string, symbolize_names: true)

  @batch_read_result = Aws::Record::Batch.read do |db|
    key_batch.each do |item_key|
      case item_key[:model]
      when 'Parent'
        formatted_key = remove_model_key(item_key)
        db.find(@parent, formatted_key)
      when 'Child'
        formatted_key = remove_model_key(item_key)
        db.find(@model, formatted_key)
      else
        raise 'Model must be either a Parent or Child'
      end
    end
  end
end

Then(/^we expect the batch read result to include the following items:$/) do |string|
  expected = JSON.parse(string, symbolize_names: true)
  actual = @batch_read_result.items.map do |item|
    item.to_h
  end
  expect(expected.count).to eq(actual.count)
  expect(expected.all? { |e| actual.include?(e) }).to be_truthy
end

private
def remove_model_key(item)
  item.delete(:model)
  item
end