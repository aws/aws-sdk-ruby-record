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
      describe StringMarshaler do

        describe 'type casting' do
          it 'type casts nil as nil' do
            expect(StringMarshaler.type_cast(nil)).to be_nil
          end

          it 'type casts nil as an empty string with an option' do
            value = StringMarshaler.type_cast(nil, nil_as_empty_string: true)
            expect(value).to eq('')
          end

          it 'type casts an empty string as nil by default' do
            expect(StringMarshaler.type_cast('')).to be_nil
          end

          it 'type casts a string as a string' do
            expect(StringMarshaler.type_cast("Hello")).to eq("Hello")
          end

          it 'type casts other types as a string' do
            expect(StringMarshaler.type_cast(5)).to eq("5")
          end
        end

        describe 'serialization for storage' do
          it 'stores strings as themselves' do
            expect(StringMarshaler.serialize("Hello")).to eq("Hello")
          end

          it 'attempts to type cast before storage' do
            expect(StringMarshaler.serialize(5)).to eq("5")
          end

          it 'identifies nil objects as the NULL type' do
            expect(StringMarshaler.serialize(nil)).to eq(nil)
          end

          it 'always serializes empty strings as NULL' do
            expect(StringMarshaler.serialize('')).to eq(nil)
          end

          it 'raises if #type_cast failed to create a string' do
            impossible = Class.new { def to_s; 5; end }.new
            expect {
              StringMarshaler.serialize(impossible)
            }.to raise_error(ArgumentError)
          end
        end

      end
    end
  end
end
