# frozen_string_literal: true

require 'spec_helper'

module Aws
  module Record
    module Marshalers
      describe FloatMarshaler do
        context 'default settings' do
          before(:each) do
            @marshaler = FloatMarshaler.new
          end

          describe 'type casting' do
            it 'casts nil and empty strings as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
              expect(@marshaler.type_cast('')).to be_nil
            end

            it 'casts stringy floats to a float' do
              expect(@marshaler.type_cast('5.5')).to eq(5.5)
            end

            it 'passes through float values' do
              expect(@marshaler.type_cast(1.2)).to eq(1.2)
            end

            it 'handles classes which do not directly serialize to floats' do
              indirect = Class.new do
                def to_s
                  '5'
                end
              end

              expect(@marshaler.type_cast(indirect.new)).to eq(5.0)
            end
          end

          describe 'serialization for storage' do
            it 'serializes nil as null' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end

            it 'serializes floats with the numeric type' do
              expect(@marshaler.serialize(3.0)).to eq(3.0)
            end

            it 'raises when type_cast does not do what it is expected to do' do
              impossible = Class.new do
                def to_f
                  'wrong'
                end
              end

              expect {
                @marshaler.serialize(impossible.new)
              }.to raise_error(ArgumentError)
            end
          end
        end
      end
    end
  end
end
