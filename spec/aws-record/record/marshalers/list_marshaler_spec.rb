# frozen_string_literal: true

require 'spec_helper'

module Aws
  module Record
    module Marshalers
      describe ListMarshaler do
        context 'default settings' do
          before(:each) do
            @marshaler = ListMarshaler.new
          end

          describe 'type casting' do
            it 'type casts nil as nil' do
              expect(@marshaler.type_cast(nil)).to eq(nil)
            end

            it 'type casts an empty string as nil' do
              expect(@marshaler.type_cast('')).to eq(nil)
            end

            it 'type casts Arrays as themselves' do
              expect(@marshaler.type_cast([1, 'Two', 3])).to eq([1, 'Two', 3])
            end

            it 'type casts enumerables as an Array' do
              expected = [[:a, 1], [:b, 2], [:c, 3]]
              input = { a: 1, b: 2, c: 3 }
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'raises if it cannot type cast to an Array' do
              expect {
                @marshaler.type_cast(5)
              }.to raise_error(ArgumentError)
            end
          end

          describe 'serialization' do
            it 'serializes an array as itself' do
              expect(@marshaler.serialize([1, 2, 3])).to eq([1, 2, 3])
            end

            it 'serializes nil as nil' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end
          end
        end
      end
    end
  end
end
