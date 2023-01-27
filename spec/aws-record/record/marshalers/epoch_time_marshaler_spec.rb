# frozen_string_literal: true

require 'spec_helper'
require 'time'

module Aws
  module Record
    module Marshalers
      describe EpochTimeMarshaler do
        context 'default settings' do
          before(:each) do
            @marshaler = EpochTimeMarshaler.new
          end

          describe 'type casting' do
            it 'casts nil and empty string as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
              expect(@marshaler.type_cast('')).to be_nil
            end

            it 'passes through Time objects' do
              expected = Time.at(1_531_173_732)
              input = Time.at(1_531_173_732)
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts timestamps to Time' do
              expected = Time.at(1_531_173_732)
              input = 1_531_173_732
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts BigDecimal objects to Time' do
              expected = Time.at(1_531_173_732)
              input = BigDecimal(1_531_173_732)
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts DateTimes to Time' do
              expected = Time.parse('2009-02-13 23:31:30 UTC')
              input = DateTime.parse('2009-02-13 23:31:30 UTC')
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts strings to Time' do
              expected = Time.parse('2009-02-13 23:31:30 UTC')
              input = '2009-02-13 23:31:30 UTC'
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'converts automatically to utc' do
              expected = Time.parse('2016-07-20 23:31:10 UTC')
              input = '2016-07-20 16:31:10 -0700'
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'raises when unable to parse as a Time' do
              expect {
                @marshaler.type_cast('that time when')
              }.to raise_error(ArgumentError)
            end
          end

          describe 'serialization for storage' do
            it 'serializes nil as null' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end

            it 'serializes Time in epoch seconds' do
              t = Time.parse('2018-07-09 22:02:12 UTC')
              expect(@marshaler.serialize(t)).to eq(1_531_173_732)
            end
          end
        end

        context 'use local time' do
          before(:each) do
            @marshaler = TimeMarshaler.new(use_local_time: true)
          end

          it 'does not automatically convert to utc' do
            expected = Time.parse('2016-07-20 16:31:10 -0700')
            input = '2016-07-20 16:31:10 -0700'
            expect(@marshaler.type_cast(input)).to eq(expected)
          end
        end
      end
    end
  end
end
