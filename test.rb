require "test/unit/assertions"
include Test::Unit::Assertions

require_relative "pratt"

assert_equal 0, pratt("0")
assert_equal 1, pratt("1")
