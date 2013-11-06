# BulkCacheFetcher

[![Build Status](https://travis-ci.org/justinweiss/bulk_cache_fetcher.png?branch=master)](https://travis-ci.org/justinweiss/bulk_cache_fetcher) [![Code Climate](https://codeclimate.com/github/justinweiss/bulk_cache_fetcher.png)](https://codeclimate.com/github/justinweiss/bulk_cache_fetcher)

Bulk Cache Fetcher fills the gap between [Russian doll caching](http://37signals.com/svn/posts/3113-how-key-based-cache-expiration-works) and the n+1 queries problem.

Russian doll caching is really great for handling views and
partials. When those partials show highly nested objects, though,
cache misses are expensive. Usually, you'll either preload the entire
object hierarchies in your controller (even on cache hits), or you'll
accept the n+1 queries when you miss the cache.

Bulk Cache Fetcher allows you to query the cache for a list of
objects, and gives you the opportunity to fetch all of the cache
misses at once, using whatever `:include`s you want.

For example, if you have a list of objects by id to fetch, and a list
of keys you want them to be cached under, you'd use Bulk Cache Fetcher
like this:

```ruby
identifiers = {:cache_key_1 => 1, :cache_key_2 => 2, :cache_key_3 => 3}
BulkCacheFetcher.new(Rails.cache).fetch(identifiers) do |uncached_keys_and_ids|
  ids = uncached_keys_and_ids.values
  BlogPost.where(:id => ids).includes([:author, :comments])
end
```

This will include and cache each `BlogPost`, with comments and
authors, as if you did the `.where.includes` without caching. If a
`BlogPost` is cached already, it won't fetch it (or its includes) from
the database.

## Installation

Add this line to your application's Gemfile:

    gem 'bulk_cache_fetcher'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bulk_cache_fetcher

## Usage

Basic usage is pretty simple:

```ruby
cache_fetcher = BulkCacheFetcher.new(Rails.cache)
cache_fetcher.fetch([1, 2, 3]) do |identifiers|
  Post.includes(...).find(identifiers)
end
```

it even returns them in the same order you return them in:

```ruby
results = cache_fetcher.fetch([2, 1, 3]) do |identifiers|
  expensive_calculation(identifiers) # => returns [result 2, result 1, result 3]
end

results.first # => expensive_calculation([2])
cache.read(1) # => expensive_calculation([1])
```

### Complex identifiers

In a lot of cases, you'll have a cache key along with a little bit of
extra data you'll need to find the record or perform a
calculation. You can use the cache fetcher for this, with a hash
instead of an array for the identifier list:

```ruby
cache_fetcher.fetch({:one => 1, :two => 2}) do |identifiers|
  expensive_calculation(identifiers.values)
end

cache.read(:one) # => expensive_calculation([1])
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
