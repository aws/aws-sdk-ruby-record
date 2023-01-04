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

When(/^we make a batch write call with following Parent and Child model items:$/) do |item_table|
  item_table = item_table.hashes
  Aws::Record::Batch.write do | db |
    item_table.each do | item |
      case item['model']
      when 'Parent'
        formatted_item = item.select {|k,v| k != 'model'}
        item_instance = @parent.new(formatted_item)
      when 'Child'
        formatted_item = item.select {|k,v| k != 'model'}
        item_instance = @model.new(formatted_item)
      else
        raise 'Model must be either a Parent or Child'
      end
      db.put(item_instance)
    end
  end
end

And(/^we make a batch read call for the following keys:$/) do |key_table|
  key_table = key_table.hashes
  @batch_read_result = Aws::Record::Batch.read do | db |
    key_table.each do | item_key |
      case item_key['model']
      when 'Parent'
        formatted_key = format_key(item_key)
        db.find(@parent, formatted_key)
      when 'Child'
        formatted_key = format_key(item_key)
        db.find(@model, formatted_key)
      else
        raise 'Model must be either a Parent or Child'
      end
    end
  end
end

Then(/^we expect the batch read result to include the following items:$/) do |expected_block|
  expected = eval(expected_block)
  actual = @batch_read_result.items.map do | item |
    item.to_h
  end
  result = expected.inject([]) do | merged_items, expected_item|
    actual.each do | actual_item |
      merged_items << expected_item.merge(actual_item) if expected_item == actual_item
    end
    merged_items
  end
  expect(result.count).to eq(expected.count)
end

private
def format_key(item_key)
  item_key.inject({}) do |result, (key, value)|
    result[key.to_sym] = value unless key == 'model'
    result
  end
end

