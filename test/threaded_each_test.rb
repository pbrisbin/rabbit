require 'test/unit'

require_relative '../lib/threaded-each'

class ThreadedEachTest < Test::Unit::TestCase
  def test_threaded_each
    values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    normal_results = []

    values.each do |v|
      sleep 0.1
      normal_results << v * 99
    end

    threaded_results = []

    values.threaded_each do |v|
      sleep 0.1
      threaded_results << v * 99
    end

    # assert that the two arrays contain the same values ignoring order
    # of elements
    assert (normal_results   - threaded_results).empty? &&
           (threaded_results - normal_results  ).empty?
  end
end
