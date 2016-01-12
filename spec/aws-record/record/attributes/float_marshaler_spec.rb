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
      describe FloatMarshaler do

        describe 'type casting' do
          it 'casts nil and empty strings as nil' do
            expect(FloatMarshaler.type_cast(nil)).to be_nil
            expect(FloatMarshaler.type_cast('')).to be_nil
          end

          it 'casts stringy floats to a float' do
            expect(FloatMarshaler.type_cast("5.5")).to eq(5.5)
          end

          it 'passes through float values' do
            expect(FloatMarshaler.type_cast(1.2)).to eq(1.2)
          end
        end

        describe 'serialization for storage' do
          it 'serializes nil as null' do
            expect(FloatMarshaler.serialize(nil)).to eq(nil)
          end

          it 'serializes floats with the numeric type' do
            expect(FloatMarshaler.serialize(3.0)).to eq(3.0)
          end
        end

      end
    end
  end
end
