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
require 'date'

module Aws
  module Record
    module Attributes
      describe DateTimeMarshaler do

        describe 'type casting' do
          it 'casts nil and empty string as nil' do
            expect(DateTimeMarshaler.type_cast(nil)).to be_nil
            expect(DateTimeMarshaler.type_cast('')).to be_nil
          end

          it 'passes through DateTime objects' do
            expected = DateTime.parse('2015-11-15 17:12:56 +0700')
            input = DateTime.parse('2015-11-15 17:12:56 +0700')
            expect(DateTimeMarshaler.type_cast(input)).to eq(expected)
          end

          it 'converts timestamps to DateTime' do
            expected = DateTime.parse("2009-02-13 23:31:30 UTC")
            input = 1234567890
            expect(DateTimeMarshaler.type_cast(input)).to eq(expected)
          end

          it 'converts strings to DateTime' do
            expected = DateTime.parse("2009-02-13 23:31:30 UTC")
            input = "2009-02-13 23:31:30 UTC"
            expect(DateTimeMarshaler.type_cast(input)).to eq(expected)
          end
        end

        describe 'serialization for storage' do
          it 'serializes nil as null' do
            expect(DateTimeMarshaler.serialize(nil)).to eq(nil)
          end

          it 'serializes DateTime as a string' do
            dt = DateTime.parse('2009-02-13 23:31:30 UTC')
            expect(DateTimeMarshaler.serialize(dt)).to eq(
              "2009-02-13T23:31:30+00:00"
            )
          end
        end

      end
    end
  end
end
