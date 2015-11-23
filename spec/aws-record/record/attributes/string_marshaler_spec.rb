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
            expect(StringMarshaler.serialize("Hello")).to eq({s:"Hello"})
          end

          it 'attempts to type cast before storage' do
            expect(StringMarshaler.serialize(5)).to eq(s:"5")
          end

          it 'identifies nil objects as the NULL type' do
            expect(StringMarshaler.serialize(nil)).to eq({null:true})
          end

          it 'always serializes empty strings as NULL' do
            expect(StringMarshaler.serialize('')).to eq({null:true})
          end
        end

      end
    end
  end
end
