module Aws
  module Record
    module Errors

      class KeyMissing < RuntimeError; end
      class NameCollision < RuntimeError; end
      class ReservedName < RuntimeError; end
      class InvalidModel < RuntimeError; end
      class TableDoesNotExist < RuntimeError; end

    end
  end
end
