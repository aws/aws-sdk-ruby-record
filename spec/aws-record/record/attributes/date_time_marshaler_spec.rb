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
