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



Given(/^a (Parent|Child) model with definition:$/) do |model, string|
  if model == 'Parent'
    @parent = Class.new do
      include(Aws::Record)
    end
    @parent.class_eval(string)
    @table_name = @parent.table_name
  elsif model == 'Child'
    @model = Class.new(@parent) do
      include(Aws::Record)
    end
    @model.class_eval(string)
    @table_name = @model.table_name
  end
end

And(/^we create a new instance of the (Parent|Child) model with attribute value pairs:$/) do |model, string|
  data = JSON.parse(string)
  if model == 'Parent'
    @instance = @parent.new
  elsif model == 'Child'
    @instance = @model.new
  end
  data.each do |row|
    attribute, value = row
    @instance.send(:"#{attribute}=", value)
  end
end