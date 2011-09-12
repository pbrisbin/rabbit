require 'test/unit'

require "#{File.dirname(__FILE__)}/../lib/aursearch"

class AurTest < Test::Unit::TestCase
  def test_rpc_search_with_one_result
    json = Aur.call_rpc(:search, 'aurget')
    assert json.has_key?('results')
    assert_equal json['results'].length, 1
    assert_equal json['results'].first['Name'], 'aurget'
  end

  def test_rpc_search_with_many_results
    json = Aur.call_rpc(:search, 'python')
    assert json.has_key?('results')
    assert json['results'].length > 1
  end

  def test_rpc_search_with_no_results
    begin
      json = Aur.call_rpc(:search, 'xlkdjowqiehgoqiiweg')
      assert false, "Should've returned not found"
    rescue RabbitNotFoundError
      assert true # expected
    end
  end

  def test_rpc_info_single
    json = Aur.call_rpc(:multiinfo, 'aurget')
    assert json_has_key?('results')
    assert_equal json['results'].length, 1
    assert_equal json['results'].first['Name'], 'aurget'
  end

  def test_rpc_info_multiple
    json = Aur.call_rpc(:multiinfo, 'aurget cower-git')
    assert json_has_key?('results')
    assert_equal json['results'].length, 2
    assert_equal json['results'][0]['Name'], 'aurget'
    assert_equal json['results'][2]['Name'], 'cower-git'
  end

  def test_rpc_invalid_type
    begin
      x = Aur.call_rpc(:foo, 'bar')
      assert false, "Should've returned an error"
    rescue RabbitError
      assert true # expected error
    end
  end
end
