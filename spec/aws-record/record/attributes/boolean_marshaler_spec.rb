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
      describe BooleanMarshaler do

        describe 'type casting' do
          it 'type casts nil and empty strings as nil' do
            expect(BooleanMarshaler.type_cast(nil)).to be_nil
            expect(BooleanMarshaler.type_cast('')).to be_nil
          end

          it 'type casts false equivalents as false' do
            expect(BooleanMarshaler.type_cast('false')).to eq(false)
            expect(BooleanMarshaler.type_cast('0')).to eq(false)
            expect(BooleanMarshaler.type_cast(0)).to eq(false)
          end
        end

        describe 'serialization for storage' do
          it 'stores booleans as themselves' do
            expect(BooleanMarshaler.serialize(true)).to eq(true)
          end

          it 'attempts to type cast before storage' do
            expect(BooleanMarshaler.serialize(0)).to eq(false)
          end

          it 'identifies nil objects as the NULL type' do
            expect(BooleanMarshaler.serialize(nil)).to eq(nil)
          end
        end

      end
    end
  end
end
