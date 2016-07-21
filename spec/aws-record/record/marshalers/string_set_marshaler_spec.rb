# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not
# use this file except in compliance with the License. A copy of the License is
# located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions
# and limitations under the License.

require 'spec_helper'

module Aws
  module Record
    module Marshalers
      describe StringSetMarshaler do

        context 'default settings' do
          before (:each) do
            @marshaler = StringSetMarshaler.new
          end

          describe "#type_cast" do
            it 'type casts nil as an empty set' do
              expect(@marshaler.type_cast(nil)).to eq(Set.new)
            end

            it 'type casts an empty string as an empty set' do
              expect(@marshaler.type_cast('')).to eq(Set.new)
            end

            it 'type casts string sets as themselves' do
              input = Set.new(['1','2','3'])
              expected = Set.new(['1','2','3'])
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'type casts arrays to sets for you' do
              input = ["1", "2", "3", "2"]
              expected = Set.new(["1", "2", "3"])
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'attempts to stringify all contents of a set' do
              input = Set.new([1,'2',3])
              expected = Set.new(['1','2','3'])
              expect(@marshaler.type_cast(input)).to eq(expected)
            end

            it 'raises when it does not know how to typecast to a set' do
              expect {
                @marshaler.type_cast("fail")
              }.to raise_error(ArgumentError)
            end
          end

          describe "#serialize" do
            it 'serializes an empty set as nil' do
              expect(@marshaler.serialize(Set.new)).to eq(nil)
            end

            it 'serializes string sets as themselves' do
              input = Set.new(['1','2','3'])
              expected = Set.new(['1','2','3'])
              expect(@marshaler.serialize(input)).to eq(expected)
            end
          end
        end

      end
    end
  end
end
