module Aws
  module Record
    module Errors

      class KeyMissing < RuntimeError; end
      class NameCollision < RuntimeError; end

    end
  end
end
