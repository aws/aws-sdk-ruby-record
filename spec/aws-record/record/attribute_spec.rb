require 'spec_helper'

module Aws
  module Record
    describe Attribute do

      let(:noop_marshaler) do
        Class.new do
          def self.type_cast(raw)
            raw
          end
          def self.serialize(raw)
            raw
          end
        end
      end

      it 'can have a custom DB name'

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
          a = Attribute.new("test", noop_marshaler, [noop_validator])
          expect(a.valid?("Hello")).to eq(true)
        end

        it 'fails validation if any validator in the chain fails' do
          a = Attribute.new(
            "test",
            noop_marshaler,
            [failure_validator, noop_validator]
          )
          expect(a.valid?("Hello")).to eq(false)
        end

      end

    end
  end
end
