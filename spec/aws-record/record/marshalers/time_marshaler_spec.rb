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
require 'time'

module Aws
  module Record
    module Marshalers
      describe TimeMarshaler do

        context 'default settings' do
          before(:each) do
            @marshaler = TimeMarshaler.new
          end

          describe 'type casting' do
            it 'casts nil and empty string as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
              expect(@marshaler.type_cast('')).to be_nil
            end

            it 'passes through Time objects' do
              expected = Time.parse('2015-11-15 17:12:56 +0700')
              input = Time.parse('2015-11-15 17:12:56 +0700')
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts timestamps to Time' do
              expected = Time.parse("2009-02-13 23:31:30 UTC")
              input = 1234567890
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts Dates to Time' do
              expected = Time.parse("2009-02-13 08:00:00 UTC")
              input = Date.parse("2009-02-13")
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts DateTimes to Time' do
              expected = Time.parse("2009-02-13 23:31:30 UTC")
              input = DateTime.parse("2009-02-13 23:31:30 UTC")
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts strings to Time' do
              expected = Time.parse("2009-02-13 23:31:30 UTC")
              input = "2009-02-13 23:31:30 UTC"
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts automatically to utc' do
              expected = Time.parse("2016-07-20 23:31:10 UTC")
              input = "2016-07-20 16:31:10 -0700"
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'raises when unable to parse as a Time' do
              expect {
                @marshaler.type_cast("that time when")
              }.to raise_error(ArgumentError)
            end
          end

          describe 'serialization for storage' do
            it 'serializes nil as null' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end

            it 'serializes Time as a string' do
              t = Time.parse('2009-02-13 23:31:30 UTC')
              expect(@marshaler.serialize(t)).to eq(
                "2009-02-13T23:31:30Z"
              )
            end
          end
        end

        context "use local time" do
          before(:each) do
            @marshaler = TimeMarshaler.new(use_local_time: true)
          end

          it 'does not automatically convert to utc' do
            expected = Time.parse("2016-07-20 16:31:10 -0700")
            input = "2016-07-20 16:31:10 -0700"
            expect(@marshaler.type_cast(input)).to eq(expected)
          end
        end

        context "bring your own format" do
          let(:rfc2822_formatter) do
            Class.new do
              def self.format(time)
                time.rfc2822
              end
            end
          end

          before(:each) do
            @marshaler = TimeMarshaler.new(formatter: rfc2822_formatter)
          end

          it 'supports custom formatting' do
            expected = "Wed, 20 Jul 2016 23:34:36 -0000"
            input = "2016-07-20T16:34:36-07:00"
            expect(@marshaler.serialize(input)).to eq(expected)
          end
        end

      end
    end
  end
end
