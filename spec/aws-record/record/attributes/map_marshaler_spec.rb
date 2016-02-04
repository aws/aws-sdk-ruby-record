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
      describe MapMarshaler do

        let(:mappable) do
          Class.new do
            def to_h
              { a: 1, b: "Two", c: 3.0 }
            end
          end
        end

        describe 'type casting' do
          it 'type casts nil as nil' do
            expect(MapMarshaler.type_cast(nil)).to eq(nil)
          end

          it 'type casts nil as an empty map with option' do
            expect(
              MapMarshaler.type_cast(nil, nil_as_empty_map: true)
            ).to eq({})
          end

          it 'type casts an empty string as nil' do
            expect(MapMarshaler.type_cast('')).to eq(nil)
          end

          it 'type casts an empty string as an empty map with option' do
            expect(
              MapMarshaler.type_cast('', nil_as_empty_map: true)
            ).to eq({})
          end

          it 'type casts Hashes as themselves' do
            input = { a: 1, b: "Two", c: 3.0 }
            expected = { a: 1, b: "Two", c: 3.0 }
            expect(MapMarshaler.type_cast(input)).to eq(expected)
          end

          it 'type casts classes which respond to :to_h as a Hash' do
            input = mappable.new
            expected = { a: 1, b: "Two", c: 3.0 }
            expect(MapMarshaler.type_cast(input)).to eq(expected)
          end

          it 'raises if it cannot type cast to a Hash' do
            expect {
              MapMarshaler.type_cast(5)
            }.to raise_error(ArgumentError)
          end
        end

        describe 'serialization' do
          it 'serializes a map as itself' do
            input = { a: 1, b: "Two", c: 3.0 }
            expected = { a: 1, b: "Two", c: 3.0 }
            expect(MapMarshaler.serialize(input)).to eq(expected)
          end

          it 'serializes nil as nil' do
            expect(MapMarshaler.serialize(nil)).to eq(nil)
          end
        end

      end
    end
  end
end
