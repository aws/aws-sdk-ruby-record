# frozen_string_literal: true

require 'spec_helper'

module Aws
  module Record
    module Marshalers
      describe IntegerMarshaler do

        context 'default settings' do
          before(:each) do
            @marshaler = IntegerMarshaler.new
          end

          describe 'type casting' do
            it 'casts nil and empty strings as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
              expect(@marshaler.type_cast('')).to be_nil
            end

            it 'casts stringy integers to an integer' do
              expect(@marshaler.type_cast("5")).to eq(5)
            end

            it 'passes through integer values' do
              expect(@marshaler.type_cast(1)).to eq(1)
            end

            it 'type casts values that do not directly respond to to_i' do
              indirect = Class.new { def to_s; "5"; end }.new
              expect(@marshaler.type_cast(indirect)).to eq(5)
            end
          end

          describe 'serialization for storage' do
            it 'serializes nil as null' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end

            it 'serializes integers with the numeric type' do
              expect(@marshaler.serialize(3)).to eq(3)
            end

            it 'raises when type_cast does not return the expected type' do
              impossible = Class.new { def to_i; "wrong"; end }.new
              expect {
                @marshaler.serialize(impossible)
              }.to raise_error(ArgumentError)
            end
          end
        end

      end
    end
  end
end
