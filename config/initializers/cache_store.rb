#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

last_cache_config = {}
load_cache_config = -> do
  Switchman.config[:cache_map] = {}

  Switchman::DatabaseServer.all.each do |db|
    db.instance_variable_set(:@cache_store, nil)
  end

  searched = Set.new
  clusters_to_search = Switchman::DatabaseServer.all.map(&:id)
  while !clusters_to_search.empty?
    cluster = clusters_to_search.shift
    next if searched.include?(cluster)
    searched << cluster
    config = Canvas.cache_store_config_for(cluster)

    # link to another cluster
    if config.is_a?(String)
      clusters_to_search << config
      Switchman.config[:cache_map][cluster] = config
      next
    end

    unless config.present?
      Switchman.config[:cache_map].delete(cluster)
      next
    end

    last_cluster_cache_config = last_cache_config[cluster]
    last_cache_config[cluster] = config

    if last_cluster_cache_config != config
      Switchman.config[:cache_map][cluster] = Canvas.lookup_cache_store(config, cluster)
    end
  end

  # resolve links
  Switchman.config[:cache_map].each_key do |cluster|
    value = cluster
    while value.is_a?(String)
      value = Switchman.config[:cache_map][value]
    end
    Switchman.config[:cache_map][cluster] = value
  end

  # fallback for no configuration whatsoever
  Switchman.config[:cache_map][Rails.env] ||= ActiveSupport::Cache.lookup_store(:null_store)
end
load_cache_config.call
Canvas::Reloader.on_reload(&load_cache_config)

ActiveSupport::Notifications.subscribe("cache_generate.active_support") do |_name, start, finish, _id, _options|
  elapsed_time = finish - start
  # used by Redis::Client#log_request_response added in lib/canvas/redis.rb
  Thread.current[:last_cache_generate] = elapsed_time
end
