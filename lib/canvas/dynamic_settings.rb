require 'diplomat'

module Canvas
  class DynamicSettings

    class ConsulError < StandardError
    end

    KV_NAMESPACE = "/config/canvas".freeze

    class << self
      attr_accessor :config, :cache

      def config=(conf_hash)
        @config = conf_hash
        if conf_hash.present?
          Diplomat.configure do |diplomat_conf|
            protocol = conf_hash.fetch("ssl", true) ? "https" : "http"
            host_and_port = "#{conf_hash.fetch('host')}:#{conf_hash.fetch('port')}"
            diplomat_conf.url = "#{protocol}://#{host_and_port}"
            diplomat_conf.acl_token = conf_hash.fetch("acl_token", nil)
          end

          init_data = conf_hash.fetch("init_values", {})
          init_values(init_data)
        end
      end

      def find(key)
        raise(ConsulError, "Unable to contact consul without config") if config.nil?
        config_records = store_get(key)
        config_records.each_with_object({}) do |node, hash|
          hash[node[:key].split("/").last] = node[:value]
        end
      end

      # settings found this way with nil expiry will be cached in the process
      # the first time they're asked for, and then can only be cleared with a SIGHUP
      # or restart of the process.  Make sure that's the behavior you want before
      # you use this method, or specify a timeout
      def from_cache(key, expires_in: nil)
        reset_cache! if cache.nil?
        cached_value = get_from_cache(key, expires_in)
        return cached_value if cached_value.present?
        # cache miss or timeout
        value = self.find(key)
        set_in_cache(key, value)
        value
      end

      def reset_cache!(hard: false)
        @cache = {}
        @strategic_reserve = {} if hard
      end

      private

      def get_from_cache(key, timeout)
        return nil unless cache.key?(key)
        cache_entry = cache[key]
        return cache_entry[:value] if timeout.nil?
        threshold = (Time.zone.now - timeout).to_i
        return cache_entry[:value] if cache_entry[:timestamp] > threshold
      end

      def set_in_cache(key, value)
        cache[key] = {value: value, timestamp: Time.zone.now.to_i}
      end

      def init_values(hash)
        hash.each do |parent_key, settings|
          settings.each do |child_key, value|
            store_put("#{parent_key}/#{child_key}", value)
          end
        end
      end

      def store_get(key)
        begin
          # store all values that we get here to
          # kind-of recover in case of big failure
          @strategic_reserve ||= {}
          consul_value = Canvas.timeout_protection('consul', {raise_on_timeout: true}) do
            Diplomat::Kv.get("#{KV_NAMESPACE}/#{key}", {recurse: true, consistency: 'stale'})
          end
          @strategic_reserve[key] = consul_value
          consul_value
        rescue Faraday::ConnectionFailed,
               Faraday::ClientError,
               Timeout::Error,
               TimeoutCutoff => exception
          if @strategic_reserve.key?(key)
            # we have an old value for this key, log the error but recover
            Canvas::Errors.capture_exception(:consul, exception)
            return @strategic_reserve[key]
          else
            # didn't have an old value cached, raise the error
            raise
          end
        end
      end

      def store_put(key, value)
        Canvas.timeout_protection('consul') do
          Diplomat::Kv.put("#{KV_NAMESPACE}/#{key}", value)
        end
      end
    end

  end
end
