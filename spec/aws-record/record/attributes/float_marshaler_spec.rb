module Aws
  module Record
    module Attributes
      describe FloatMarshaler do

        describe 'type casting' do
          it 'casts nil and empty strings as nil' do
            expect(FloatMarshaler.type_cast(nil)).to be_nil
            expect(FloatMarshaler.type_cast('')).to be_nil
          end

          it 'casts stringy floats to a float' do
            expect(FloatMarshaler.type_cast("5.5")).to eq(5.5)
          end

          it 'passes through float values' do
            expect(FloatMarshaler.type_cast(1.2)).to eq(1.2)
          end
        end

        describe 'serialization for storage' do
          it 'serializes nil as null' do
            expect(FloatMarshaler.serialize(nil)).to eq({null: true})
          end

          it 'serializes floats with the numeric type' do
            expect(FloatMarshaler.serialize(3.0)).to eq({n: 3.0})
          end
        end

      end
    end
  end
end
