require 'test_helper'

class InMemoryCache
  attr_accessor :cache, :options

  def initialize(options = {})
    @cache = {}
    @options = {}
  end

  def read(key); cache[key]; end
  def write(key, value, opts = {}); options[key] = opts; cache[key] = value; end
  def read_multi(*keys)
    results = {}
    keys.each do |key|
      results[key] = read(key) if cache.has_key?(key)
    end
    results
  end

end

class BulkCacheFetcherTest < Minitest::Unit::TestCase

  def setup
    @cache = InMemoryCache.new
    @cache_fetcher = BulkCacheFetcher.new(@cache)
  end

  def test_returns_all_results_in_order
    results = @cache_fetcher.fetch([5, 2, 3, 1, 4]) do |unfetched_objects|
      unfetched_objects
    end
    assert_equal [5, 2, 3, 1, 4], results
  end

  def test_returns_without_calling_block_if_cached
    counter = 0
    @cache.write(1, 3)
    @cache.write(2, 4)

    results = @cache_fetcher.fetch([2, 1]) do |unfetched_objects|
      counter += 1
      unfetched_objects.map { |i| i += 2 }
    end

    assert_equal [4, 3], results
    assert_equal 0, counter
  end

  def test_returns_some_from_cache_in_correct_order
    counter = 0
    @cache.write(1, 3)
    @cache.write(2, 4)

    results = @cache_fetcher.fetch([2, 3, 1, 4]) do |unfetched_objects|
      counter += unfetched_objects.length
      unfetched_objects.map { |i| i += 2 }
    end

    assert_equal [4, 5, 3, 6], results
    assert_equal 2, counter
  end

  def test_uncached_records_stored_in_cache
    @cache_fetcher.fetch([2, 3]) do |unfetched_objects|
      unfetched_objects.map { |i| i += 2 }
    end

    assert_equal 4, @cache.read(2)
    assert_equal 5, @cache.read(3)
  end

  def test_cache_key_with_associated_data
    counter = 0
    @cache.write(:one, 3)

    identifiers = {three: 3, one: 1, two: 2}
    results = @cache_fetcher.fetch(identifiers) do |unfetched_objects|
      counter += unfetched_objects.length
      unfetched_objects.values.map { |i| i += 2 }
    end

    assert_equal [5, 3, 4], results
    assert_equal 2, counter
  end

  def test_succeeds_without_keys
    results = @cache_fetcher.fetch([])
    assert_equal [], results
  end

  def test_fails_with_too_many_keys
    assert_raises ArgumentError do
      @cache_fetcher.fetch([1, 2]) do |keys|
        [1]
      end
    end
  end

  def test_fails_with_too_many_values
    assert_raises ArgumentError do
      @cache_fetcher.fetch([1, 2]) do |keys|
        [1, 2, 3]
      end
    end
  end

  def test_can_take_cache_options
    @cache_fetcher.fetch([1, 2], expires_in: 300) do |keys|
      [1, 2]
    end
    assert_equal({expires_in: 300}, @cache.options[2])
  end

  def test_can_take_single_cache_key
    @cache_fetcher.fetch(1) do |keys|
      2
    end
    assert_equal(2, @cache.read(1))
  end

  def test_complex_key_caches_under_correct_key
    @cache_fetcher.fetch({:one => 1}) do |keys|
      2
    end
    assert_equal(2, @cache.read(:one))
  end

  def test_doesnt_break_if_nils_are_cached
    @cache.write(:two, nil)
    results = @cache_fetcher.fetch([:one, :two, :three]) do |keys|
      [1, 3]
    end
    assert_equal(nil, results[1])
    assert_equal(3, results[2])
  end
end
