# frozen_string_literal: true

require 'spec_helper'
require 'date'

module Aws
  module Record
    module Marshalers
      describe DateTimeMarshaler do

        context 'default settings' do
          before(:each) do
            @marshaler = DateTimeMarshaler.new
          end

          describe 'type casting' do
            it 'casts nil and empty string as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
              expect(@marshaler.type_cast('')).to be_nil
            end

            it 'passes through DateTime objects' do
              expected = DateTime.parse('2015-11-15 17:12:56 +0700')
              input = DateTime.parse('2015-11-15 17:12:56 +0700')
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts timestamps to DateTime' do
              expected = DateTime.parse("2009-02-13 23:31:30 UTC")
              input = 1234567890
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts strings to DateTime' do
              expected = DateTime.parse("2009-02-13 23:31:30 UTC")
              input = "2009-02-13 23:31:30 UTC"
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts automatically to utc' do
              expected = DateTime.parse("2016-07-20 23:31:10 UTC")
              input = "2016-07-20 16:31:10 -0700"
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'raises when unable to parse as a DateTime' do
              expect {
                @marshaler.type_cast("that time when")
              }.to raise_error(ArgumentError)
            end
          end

          describe 'serialization for storage' do
            it 'serializes nil as null' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end

            it 'serializes DateTime as a string' do
              dt = DateTime.parse('2009-02-13 23:31:30 UTC')
              expect(@marshaler.serialize(dt)).to eq(
                "2009-02-13T23:31:30+00:00"
              )
            end
          end
        end

        context "use local time" do
          before(:each) do
            @marshaler = DateTimeMarshaler.new(use_local_time: true)
          end

          it 'does not automatically convert to utc' do
            expected = DateTime.parse("2016-07-20 16:31:10 -0700")
            input = "2016-07-20 16:31:10 -0700"
            expect(@marshaler.type_cast(input)).to eq(expected)
          end
        end

        context "bring your own format" do
          let(:jisx0301_formatter) do
            Class.new do
              def self.format(datetime)
                datetime.jisx0301
              end
            end
          end
          
          before(:each) do
            @marshaler = DateTimeMarshaler.new(formatter: jisx0301_formatter)
          end

          it 'supports custom formatting' do
            expected = "H28.07.20T23:34:36+00:00"
            input = "2016-07-20T16:34:36-07:00"
            expect(@marshaler.serialize(input)).to eq(expected)
          end
        end

      end
    end
  end
end
