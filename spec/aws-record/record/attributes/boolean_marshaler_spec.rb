require 'spec_helper'

module Aws
  module Record
    module Attributes
      describe BooleanMarshaler do

        describe 'type casting' do
          it 'type casts nil and empty strings as nil' do
            expect(BooleanMarshaler.type_cast(nil)).to be_nil
            expect(BooleanMarshaler.type_cast('')).to be_nil
          end

          it 'type casts false equivalents as false' do
            expect(BooleanMarshaler.type_cast('false')).to eq(false)
            expect(BooleanMarshaler.type_cast('0')).to eq(false)
            expect(BooleanMarshaler.type_cast(0)).to eq(false)
          end
        end

        describe 'serialization for storage' do
          it 'stores booleans as themselves' do
            expect(BooleanMarshaler.serialize(true)).to eq(true)
          end

          it 'attempts to type cast before storage' do
            expect(BooleanMarshaler.serialize(0)).to eq(false)
          end

          it 'identifies nil objects as the NULL type' do
            expect(BooleanMarshaler.serialize(nil)).to eq(nil)
          end
        end

      end
    end
  end
end
