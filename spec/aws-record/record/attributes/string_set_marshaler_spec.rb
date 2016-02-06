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
    module Attributes
      describe StringSetMarshaler do

        describe "#type_cast" do
          it 'type casts nil as an empty set' do
            expect(StringSetMarshaler.type_cast(nil)).to eq(Set.new)
          end

          it 'type casts an empty string as an empty set' do
            expect(StringSetMarshaler.type_cast(nil)).to eq(Set.new)
          end

          it 'type casts string sets as themselves' do
            input = Set.new(['1','2','3'])
            expected = Set.new(['1','2','3'])
            expect(StringSetMarshaler.type_cast(input)).to eq(expected)
          end

          it 'attempts to stringify all contents of a set' do
            input = Set.new([1,'2',3])
            expected = Set.new(['1','2','3'])
            expect(StringSetMarshaler.type_cast(input)).to eq(expected)
          end
        end

        describe "#serialize" do
          it 'serializes an empty set as nil' do
            expect(StringSetMarshaler.serialize(Set.new)).to eq(nil)
          end

          it 'serializes string sets as themselves' do
            input = Set.new(['1','2','3'])
            expected = Set.new(['1','2','3'])
            expect(StringSetMarshaler.serialize(input)).to eq(expected)
          end
        end

      end
    end
  end
end
