# frozen_string_literal: true

require 'spec_helper'

module Aws
  module Record
    module Marshalers
      describe BooleanMarshaler do
        context 'default settings' do
          before(:each) do
            @marshaler = BooleanMarshaler.new
          end

          describe 'type casting' do
            it 'type casts nil and empty strings as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
              expect(@marshaler.type_cast('')).to be_nil
            end

            it 'type casts false equivalents as false' do
              expect(@marshaler.type_cast('false')).to eq(false)
              expect(@marshaler.type_cast('0')).to eq(false)
              expect(@marshaler.type_cast(0)).to eq(false)
            end
          end

          describe 'serialization for storage' do
            it 'stores booleans as themselves' do
              expect(@marshaler.serialize(true)).to eq(true)
            end

            it 'attempts to type cast before storage' do
              expect(@marshaler.serialize(0)).to eq(false)
            end

            it 'identifies nil objects as the NULL type' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end
          end
        end
      end
    end
  end
end
