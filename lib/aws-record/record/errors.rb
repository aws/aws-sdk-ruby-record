module Aws
  module Record
    module Errors

      class KeyMissing < RuntimeError; end
      class NameCollision < RuntimeError; end
      class ReservedName < RuntimeError; end

    end
  end
end
