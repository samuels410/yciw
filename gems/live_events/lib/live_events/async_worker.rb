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
#

require 'thread'

module LiveEvents

  # TODO: Consider refactoring out common functionality from this and
  # CanvasPandaPub::AsyncWorker. Their semantics are a bit different so
  # it may not make sense.

  # TODO: Consider adding batched requests. Kinesis has a put_records call
  # that is more efficient. (Would also require using aws-sdk-v2 instead of v1.)
  #
  # If we do that, we'll want to add an at_exit handler that flushes out the
  # queue for cases when the process is shutting down.

  class AsyncWorker
    attr_reader :logger

    MAX_BYTE_THRESHOLD = 5_000_000
    KINESIS_RECORD_SIZE_LIMIT = 1_000_000

    def initialize(start_thread = true, stream_client:, stream_name:)
      @queue = Queue.new
      @logger = LiveEvents.logger
      @stream_client = stream_client
      @stream_name = stream_name

      self.start! if start_thread
    end

    def push(event, partition_key = SecureRandom.uuid)
      if @queue.length >= LiveEvents.max_queue_size
        return false
      end
      event_json = event.to_json
      total_bytes = event_json.bytesize + partition_key.bytesize
      if total_bytes > KINESIS_RECORD_SIZE_LIMIT
        logger.error("Record size greater than #{KINESIS_RECORD_SIZE_LIMIT}")
        return false
      end

      @queue << {
        data: event_json,
        partition_key: partition_key,
        statsd_prefix: "live_events.events.#{event[:attributes][:event_name]}",
        total_bytes: total_bytes
      }
      true
    end

    def stopped?
      @thread.nil? || !@thread.alive?
    end

    def stop!
      logger.info("Draining live events queue")
      @running = false
      # activate the thread so it won't error on join
      @queue << :stop
      @thread.join
      logger.info("Live events async worker stopped")
    end

    def start!
      @thread = Thread.new { self.run_thread }
      @running = true
      at_exit { stop! }
    end

    def run_thread
      loop do
        return unless @running || @queue.size > 0
        # pause thread so it will allow main thread to run
        r = @queue.pop if @queue.size == 0

        begin
          # r will be nil on first pass
          records = [r].compact
          total_bytes = r&.fetch(:total_bytes) || 0
          while @queue.size > 0 && total_bytes < MAX_BYTE_THRESHOLD
            r = @queue.pop
            break if r == :stop

            if r[:total_bytes] + total_bytes > MAX_BYTE_THRESHOLD
              # put back on queue, will overflow kinesis put byte limit
              @queue << r
            else
              records << r
            end
            total_bytes += r[:total_bytes]
          end
          send_events(records)
        rescue Exception => e
          logger.error("Exception making LiveEvents async call: #{e}")
        end
      end
    end

    private

    def send_events(records)
      return if records.empty?

      res = @stream_client.put_records(
        records: records.map do |record|
          {
            data: record[:data],
            partition_key: record[:partition_key]
          }
        end,
        stream_name: @stream_name
      )
      process_results(res, records)
    end

    def process_results(res, records)
      res.records.each_with_index do |r, i|
        if r.error_code.present?
          log_unprocessed(records[i])
        else
          LiveEvents&.statsd&.increment("#{records[i][:statsd_prefix]}.sends")
          nil
        end
      end.compact
    end

    def log_unprocessed(record)
      logger.error("Error posting event #{record[:statsd_prefix]} with partition key #{record[:partition_key]}: #{record[:data]}")
      LiveEvents&.statsd&.increment("#{record[:statsd_prefix]}.send_errors")
    end
  end
end
