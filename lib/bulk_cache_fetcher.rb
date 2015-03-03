# Fetches many objects from a cache in order. In the event that some
# objects can't be served from the cache, you will have the
# opportunity to fetch them in bulk. This allows you to preload and
# cache entire object hierarchies, which works particularly well with
# Rails' nested caching while avoiding the n+1 queries problem in the
# uncached case.
class BulkCacheFetcher
  VERSION = '1.0.0'

  # Creates a new bulk cache fetcher, backed by +cache+. Cache must
  # respond to the standard Rails cache API, described on
  # http://guides.rubyonrails.org/caching_with_rails.html
  def initialize(cache)
    @cache = cache
  end

  # Returns a list of objects identified by
  # <tt>object_identifiers</tt>. +fetch+ will try to find the objects
  # from the cache first. Identifiers for objects that aren't in the
  # cache will be passed as an ordered list to <tt>finder_block</tt>,
  # where you can find the objects as you see fit. These objects
  # should be returned in the same order as the identifiers that were
  # passed into the block, because they'll be cached under their
  # respective keys. The objects returned by +fetch+ will be returned
  # in the same order as the <tt>object_identifiers</tt> passed in.
  #
  # +options+ will be passed along unmodified when caching newly found
  # objects, so you can use it for things like setting cache
  # expiration.
  def fetch(object_identifiers, options = {}, &finder_block)
    object_identifiers = normalize(object_identifiers)
    cached_keys_with_objects, uncached_identifiers = partition(object_identifiers)
    found_objects = find(uncached_identifiers, options, &finder_block)
    coalesce(cache_keys(object_identifiers), cached_keys_with_objects, found_objects)
  end

  private

  # Splits a list of identifiers into two objects. The first is a hash
  # of <tt>{cache_key: object}</tt> for all the objects we were able to serve
  # from the cache. The second is a list of all of the identifiers for
  # objects that weren't cached.
  def partition(object_identifiers)
    uncached_identifiers = object_identifiers.dup

    cache_keys = cache_keys(object_identifiers)
    cached_keys_with_objects = @cache.read_multi(*cache_keys)

    cache_keys.each do |cache_key|
      uncached_identifiers.delete(cache_key) if cached_keys_with_objects.has_key?(cache_key)
    end

    [cached_keys_with_objects, uncached_identifiers]
  end

  # Finds all of the objects identified by +identifiers+, using the
  # +finder_block+. Will pass +options+ on to the cache.
  def find(identifiers, options = {}, &finder_block)
    return [] if identifiers.empty?
    Array(finder_block.call(identifiers)).tap do |objects|
      verify_equal_key_and_value_counts!(identifiers, objects)
      cache_all(identifiers, objects, options)
    end
  end

  # Makes sure we have enough +identifiers+ to cache all of our
  # +objects+, and vice-versa.
  def verify_equal_key_and_value_counts!(identifiers, objects)
    raise ArgumentError, "You are returning too many objects from your cache block!" if objects.length > identifiers.length
    raise ArgumentError, "You are returning too few objects from your cache block!" if objects.length < identifiers.length
  end

  # Caches all +values+ under their respective +keys+.
  def cache_all(keys, values, options = {})
    keys.zip(values) { |k, v| @cache.write(cache_key(k), v, options) }
  end

  # Given a list of +cache_keys+, either find associated objects from
  # +cached_keys_with_objects, or grab them from +found_objects+, in
  # order.
  def coalesce(cache_keys, cached_keys_with_objects, found_objects)
    found_objects = Array(found_objects)
    cache_keys.map { |key| cached_keys_with_objects.fetch(key) { found_objects.shift } }
  end

  # Returns the part of the identifier that we can use as the cache
  # key. For simple identifiers, it's just the identifier, for
  # identifiers with extra information attached, it's the first part
  # of the identifier.
  def cache_key(identifier)
    Array(identifier).first
  end

  # Returns the cache keys for all of the +identifiers+.
  def cache_keys(identifiers)
    identifiers.map { |identifier| cache_key(identifier) }
  end

  # Makes sure we can iterate over identifiers.
  def normalize(identifiers)
    identifiers.respond_to?(:each) ? identifiers : Array(identifiers)
  end
end
