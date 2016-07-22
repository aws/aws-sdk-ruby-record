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
      describe FloatMarshaler do

        context 'default settings' do
          before(:each) do
            @marshaler = FloatMarshaler.new
          end

          describe 'type casting' do
            it 'casts nil and empty strings as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
              expect(@marshaler.type_cast('')).to be_nil
            end

            it 'casts stringy floats to a float' do
              expect(@marshaler.type_cast("5.5")).to eq(5.5)
            end

            it 'passes through float values' do
              expect(@marshaler.type_cast(1.2)).to eq(1.2)
            end

            it 'handles classes which do not directly serialize to floats' do
              indirect = Class.new { def to_s; "5"; end }.new
              expect(@marshaler.type_cast(indirect)).to eq(5.0)
            end
          end

          describe 'serialization for storage' do
            it 'serializes nil as null' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end

            it 'serializes floats with the numeric type' do
              expect(@marshaler.serialize(3.0)).to eq(3.0)
            end

            it 'raises when type_cast does not do what it is expected to do' do
              impossible = Class.new { def to_f; "wrong"; end }.new
              expect {
                @marshaler.serialize(impossible)
              }.to raise_error(ArgumentError)
            end
          end
        end

      end
    end
  end
end

