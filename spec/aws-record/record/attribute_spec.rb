# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

require 'spec_helper'

module Aws
  module Record
    describe Attribute do

      context 'database_attribute_name' do
        it 'can have a custom DB name' do
          a = Attribute.new(:foo, database_attribute_name: "bar")
          expect(a.name).to eq(:foo)
          expect(a.database_name).to eq("bar")
        end

        it 'uses the attribute name by default for the DB name' do
          a = Attribute.new(:foo)
          expect(a.name).to eq(:foo)
          expect(a.database_name).to eq("foo")
        end
      end

      context 'mutation_tracking' do
        it 'does not track mutations by default' do
          a = Attribute.new(:foo)
          expect(a.track_mutations?).to eq(false)
        end

        it 'has an option to track mutations' do
          a = Attribute.new(:foo, mutation_tracking: true)
          expect(a.track_mutations?).to eq(true)
        end
      end

    end
  end
end
