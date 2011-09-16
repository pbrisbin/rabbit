require 'test/unit'

require_relative'../lib/aursearch'

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
    assert_raise(RabbitNotFoundError) { json = Aur.call_rpc(:search, 'xlkdjowqiehgoqiiweg') }
  end

  def test_rpc_info_single
    json = Aur.call_rpc(:multiinfo, 'aurget')
    assert json.has_key?('results')
    assert_equal json['results'].length, 1
    assert_equal json['results'].first['Name'], 'aurget'
  end

  def test_rpc_info_multiple
    json = Aur.call_rpc(:multiinfo, 'aurget cower-git')
    assert json.has_key?('results')
    assert_equal json['results'].length, 2
    assert_equal json['results'][0]['Name'], 'aurget'
    assert_equal json['results'][1]['Name'], 'cower-git'
  end

  def test_rpc_invalid_type
    assert_raise(RabbitError){ x = Aur.call_rpc(:foo, 'bar') }
  end
end
