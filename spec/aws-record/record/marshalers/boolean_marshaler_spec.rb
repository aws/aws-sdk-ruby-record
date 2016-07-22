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
      describe BooleanMarshaler do

        context 'default settings' do
          before(:each) do
            @marshaler = BooleanMarshaler.new
          end

          describe 'type casting' do
            it 'type casts nil and empty strings as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
              expect(@marshaler.type_cast('')).to be_nil
            end

            it 'type casts false equivalents as false' do
              expect(@marshaler.type_cast('false')).to eq(false)
              expect(@marshaler.type_cast('0')).to eq(false)
              expect(@marshaler.type_cast(0)).to eq(false)
            end
          end

          describe 'serialization for storage' do
            it 'stores booleans as themselves' do
              expect(@marshaler.serialize(true)).to eq(true)
            end

            it 'attempts to type cast before storage' do
              expect(@marshaler.serialize(0)).to eq(false)
            end

            it 'identifies nil objects as the NULL type' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end
          end
        end

      end
    end
  end
end

