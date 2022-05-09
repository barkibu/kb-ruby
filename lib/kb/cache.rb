module KB
  class Cache
    class << self
      def delete(key)
        instance.delete(key)
      end

      def fetch(key, &block)
        instance.fetch(key, expires_in: cache_expiration, &block)
      end

      private

      def instance
        KB.config.cache.instance
      end

      def cache_expiration
        KB.config.cache.expires_in.to_f
      end
    end
  end
end
