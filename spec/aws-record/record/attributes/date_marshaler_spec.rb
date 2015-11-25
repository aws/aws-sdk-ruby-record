require 'spec_helper'
require 'date'

module Aws
  module Record
    module Attributes
      describe DateMarshaler do

        describe 'type casting' do
          it 'casts nil and empty string as nil' do
            expect(DateMarshaler.type_cast(nil)).to be_nil
            expect(DateMarshaler.type_cast('')).to be_nil
          end

          it 'casts Date objects as themselves' do
            expected = Date.parse('2015-01-01')
            input = Date.parse('2015-01-01')
            expect(DateMarshaler.type_cast(input)).to eq(expected)
          end

          it 'casts timestamps to dates' do
            expected = Date.parse('2009-02-13')
            input = 1234567890
            expect(DateMarshaler.type_cast(input)).to eq(expected)
          end

          it 'casts strings to dates' do
            expected = Date.parse('2015-11-25')
            input = '2015-11-25'
            expect(DateMarshaler.type_cast(input)).to eq(expected)
          end
        end

        describe 'serialization for storage' do
          it 'serializes nil as null' do
            expect(DateMarshaler.serialize(nil)).to eq({null: true})
          end

          it 'serializes dates as strings' do
            date = Date.parse('2015-11-25')
            expect(DateMarshaler.serialize(date)).to eq({s: '2015-11-25'})
          end
        end

      end
    end
  end
end
