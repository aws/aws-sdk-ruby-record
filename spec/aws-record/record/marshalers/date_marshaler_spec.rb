# frozen_string_literal: true

require 'spec_helper'
require 'date'

module Aws
  module Record
    module Marshalers
      describe DateMarshaler do

        context 'default settings' do
          before(:each) do
            @marshaler = DateMarshaler.new
          end

          describe 'type casting' do
            it 'casts nil and empty string as nil' do
              expect(@marshaler.type_cast(nil)).to be_nil
              expect(@marshaler.type_cast('')).to be_nil
            end

            it 'casts Date objects as themselves' do
              expected = Date.parse('2015-01-01')
              input = Date.parse('2015-01-01')
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'casts timestamps to dates' do
              expected = Date.parse('2009-02-13')
              input = 1234567890
              expect(@marshaler.type_cast(input)).to be_within(1).of(expected)
            end

            it 'casts strings to dates' do
              expected = Date.parse('2015-11-25')
              input = '2015-11-25'
              expect(@marshaler.type_cast(input)).to eq(expected)
            end
          end

          describe 'serialization for storage' do
            it 'serializes nil as null' do
              expect(@marshaler.serialize(nil)).to eq(nil)
            end

            it 'serializes dates as strings' do
              date = Date.parse('2015-11-25')
              expect(@marshaler.serialize(date)).to eq('2015-11-25')
            end
          end
        end

        context "bring your own format" do
          let(:jisx0301_formatter) do
            Class.new do
              def self.format(date)
                date.jisx0301
              end
            end
          end

          before(:each) do
            @marshaler = DateMarshaler.new(formatter: jisx0301_formatter)
          end

          it 'supports custom formatting' do
            expected = "H28.07.21"
            input = "2016-07-21"
            expect(@marshaler.serialize(input)).to eq(expected)
          end
        end

      end
    end
  end
end
