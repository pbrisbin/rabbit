require 'test_helper'

class TestThreadedEach < Test::Unit::TestCase
  def test_expected_results
    expected = [1, 2, 3, 4, 5].map { |n| n * 10 }.sort
    actual   = [1, 2, 3, 4, 5].threaded_each { |n| n * 10 }.sort

    assert_equal expected, actual, "threaded each should behave like map"
  end
end
