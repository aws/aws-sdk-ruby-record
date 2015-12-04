require 'spec_helper'

module Aws
  module Record
    module Attributes
      describe IntegerMarshaler do

        describe 'type casting' do
          it 'casts nil and empty strings as nil' do
            expect(IntegerMarshaler.type_cast(nil)).to be_nil
            expect(IntegerMarshaler.type_cast('')).to be_nil
          end

          it 'casts stringy integers to an integer' do
            expect(IntegerMarshaler.type_cast("5")).to eq(5)
          end

          it 'passes through integer values' do
            expect(IntegerMarshaler.type_cast(1)).to eq(1)
          end
        end

        describe 'serialization for storage' do
          it 'serializes nil as null' do
            expect(IntegerMarshaler.serialize(nil)).to eq(nil)
          end

          it 'serializes integers with the numeric type' do
            expect(IntegerMarshaler.serialize(3)).to eq(3)
          end
        end

      end
    end
  end
end
