# frozen_string_literal: true

require 'spec_helper'

module Aws
  module Record
    module Marshalers
      describe StringMarshaler do

        context 'default settings' do
          before(:each) do
            @marshaler = StringMarshaler.new
          end

          describe 'type casting' do
            it 'type casts nil as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
            end

            it 'type casts an empty string as an empty string' do
              expect(@marshaler.type_cast('')).to eq('')
            end

            it 'type casts a string as a string' do
              expect(@marshaler.type_cast("Hello")).to eq("Hello")
            end

            it 'type casts other types as a string' do
              expect(@marshaler.type_cast(5)).to eq("5")
            end
          end

          describe 'serialization for storage' do
            it 'stores strings as themselves' do
              expect(@marshaler.serialize("Hello")).to eq("Hello")
            end

            it 'attempts to type cast before storage' do
              expect(@marshaler.serialize(5)).to eq("5")
            end

            it 'identifies nil objects as the NULL type' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end

            it 'always serializes empty strings as NULL' do
              expect(@marshaler.serialize('')).to eq(nil)
            end

            it 'raises if #type_cast failed to create a string' do
              impossible = Class.new { def to_s; 5; end }.new
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
