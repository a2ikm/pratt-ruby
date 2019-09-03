require "test/unit/assertions"
include Test::Unit::Assertions

require_relative "pratt"

assert_equal 0, pratt("0")
assert_equal 1, pratt("1")
assert_equal 3, pratt("1+2")
assert_equal 7, pratt("1+2*3")
assert_equal 5, pratt("1*2+3")
assert_equal -1, pratt("-1")
assert_equal -3, pratt("-1-2")
