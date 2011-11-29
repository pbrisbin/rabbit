require 'test_helper'

class JsonTest < Test::Unit::TestCase
  include Rabbit::Json

  def test_url_for_search
    expected = 'http://aur.archlinux.org/rpc.php?type=search&arg=something'
    actual   = url_for_search('something')

    assert_equal expected, actual
  end

  def test_url_for_info
    expected = 'http://aur.archlinux.org/rpc.php?type=multiinfo&arg[]=one&arg[]=two'
    actual   = url_for_info(['one', 'two'])
    
    assert_equal expected, actual
  end

  def test_info
    results = fetch_json(url_for_info(['aurget']))

    assert_equal 1, results.length
    assert_equal 'aurget', results.first.Name
  end

  def test_info_multi
    results = fetch_json(url_for_info(['aurget', 'cower-git']))

    assert_equal 2, results.length
    assert_equal ['aurget','cower-git'], results.map(&:Name)
  end

  def test_search
  end
end
