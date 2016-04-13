# Copyright 2015-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

module Aws
  module Record
    module Errors

      class RecordError < RuntimeError; end

      class KeyMissing < RecordError; end
      class NotFound < RecordError; end
      class ItemAlreadyExists < RecordError; end
      class NameCollision < RecordError; end
      class ReservedName < RecordError; end
      class SubmissionError < RecordError; end
      class InvalidModel < RecordError; end
      class TableDoesNotExist < RecordError; end
      class ValidationError < RecordError; end


    end
  end
end
