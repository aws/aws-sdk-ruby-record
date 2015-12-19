require 'spec_helper'

module Aws
  module Record
    describe Attribute do

      it 'can have a custom DB name' do
        a = Attribute.new(:foo, database_attribute_name: "bar")
        expect(a.name).to eq(:foo)
        expect(a.database_name).to eq("bar")
      end

      describe 'validation' do

        let(:noop_validator) do
          Class.new do
            def self.validate(value)
              true
            end
          end
        end

        let(:failure_validator) do
          Class.new do
            def self.validate(value)
              false
            end
          end
        end

        it 'passes validation on to a validator chain' do
          a = Attribute.new(:test, validators: [noop_validator])
          expect(a.valid?("Hello")).to eq(true)
        end

        it 'fails validation if any validator in the chain fails' do
          a = Attribute.new(
            :test, validators: [failure_validator, noop_validator]
          )
          expect(a.valid?("Hello")).to eq(false)
        end

      end

    end
  end
end
