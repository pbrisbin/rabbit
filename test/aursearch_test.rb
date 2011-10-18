require 'test/unit'
require_relative'../lib/aursearch'

class AurSearchTest < Test::Unit::TestCase
  include AurSearch

  def test_one_result
    [:search, :info, :pkgbuild].each do |type|
      url = AurSearch.json_request_url(type, 'aurget')
      assert_not_nil url

      AurSearch.with_json_response(url) do |json|
        assert_nothing_raised do
          results = SearchResult.init_from_json(json)
          assert_equal 1, results.length
          assert_equal 'aurget', results.first.name
        end
      end
    end
  end

  def test_no_results
    [:search, :info, :pkgbuild].each do |type|
      url = AurSearch.json_request_url(type, 'xldkadhkgoieh')
      assert_not_nil url

      AurSearch.with_json_response(url) do |json|
        assert_raise(NotFoundError) { SearchResult.init_from_json(json) }
      end
    end
  end

  def test_many_search_results
    url = AurSearch.json_request_url(:search, 'python')
    assert_not_nil url

    AurSearch.with_json_response(url) do |json|
      assert_nothing_raised do
        results = SearchResult.init_from_json(json)
        assert results.length > 1
      end
    end
  end

  def test_many_info_results
    [:info, :pkgbuild].each do |type|
      url = AurSearch.json_request_url(type, 'aurget cower-git')

      AurSearch.with_json_response(url) do |json|
        assert_nothing_raised do
          results = SearchResult.init_from_json(json)
          assert results.length > 1
          assert_equal %w(aurget cower-git), results.map(&:name).sort
        end
      end
    end

  end

  def test_invalid_type
    url = AurSearch.json_request_url(:foo, 'bar')
    assert_nil url
  end

  def test_with_pkgbuild
    url = AurSearch.json_request_url(:pkgbuild, 'aurget')

    AurSearch.with_json_response(url) do |json|
      assert_nothing_raised do
        results = SearchResult.init_from_json(json)
        results.first.with_pkgbuild do |pkgbuild|
          assert_match /name=aurget/, pkgbuild
        end
      end
    end
  end
end
