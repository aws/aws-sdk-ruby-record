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

require 'spec_helper'

module Aws
  module Record
    module Marshalers
      describe ListMarshaler do

        context 'default settings' do
          before(:each) do
            @marshaler = ListMarshaler.new
          end

          describe 'type casting' do
            it 'type casts nil as nil' do
              expect(@marshaler.type_cast(nil)).to eq(nil)
            end

            it 'type casts an empty string as nil' do
              expect(@marshaler.type_cast('')).to eq(nil)
            end

            it 'type casts Arrays as themselves' do
              expect(@marshaler.type_cast([1,"Two",3])).to eq([1, "Two", 3])
            end

            it 'type casts enumerables as an Array' do
              expected = [[:a, 1], [:b, 2], [:c, 3]]
              input = { a: 1, b: 2, c: 3 }
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'raises if it cannot type cast to an Array' do
              expect {
                @marshaler.type_cast(5)
              }.to raise_error(ArgumentError)
            end
          end

          describe 'serialization' do
            it 'serializes an array as itself' do
              expect(@marshaler.serialize([1,2,3])).to eq([1,2,3])
            end

            it 'serializes nil as nil' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end
          end
        end

      end
    end
  end
end
