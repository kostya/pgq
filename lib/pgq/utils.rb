module Pgq::Utils

  # == all queues for database
  def queues_list
    database.pgq_get_consumer_info.map{|x| x['queue_name']}.uniq
  end

  # == methods for migrations
  def add_queue(queue_name, consumer_name = self.consumer_name)
    database.pgq_create_queue(queue_name.to_s)
    database.pgq_register_consumer(queue_name.to_s, consumer_name.to_s)
  end

  def remove_queue(queue_name, consumer_name = self.consumer_name)
    database.pgq_unregister_consumer(queue_name.to_s, consumer_name.to_s)
    database.pgq_drop_queue(queue_name.to_s)
  end
  
  # == inspect queue
  # { type => events_count }
  def inspect_queue(queue_name)
    table, last_event = database.pgq_last_event_id(queue_name)
    
    stats = if last_event
      connection.select_all <<-SQL
        SELECT count(*) as count, ev_type
        FROM #{table}
        WHERE ev_id > #{last_event.to_i}
        GROUP BY ev_type
      SQL
    else    
      connection.select_all <<-SQL
        SELECT ev_type
        FROM #{table}
        GROUP BY ev_type
      SQL
    end
    
    stats.each do |x|
      result["#{x['ev_type']}"] = x['count'].to_i
    end                

    result
  end
  
  def inspect_self_queue
    self.inspect_queue(self.queue_name)
  end

  # show hash stats, for londiste type of storage events 
  # { type => events_count }
  def inspect_londiste_queue(queue_name)
    table, last_event = database.pgq_last_event_id(queue_name)
    
    stats = if last_event
      connection.select_all <<-SQL
        SELECT count(*) as count, ev_type, ev_extra1
        FROM #{table}
        WHERE ev_id > #{last_event.to_i}
        GROUP BY ev_type, ev_extra1
      SQL
    else    
      connection.select_all <<-SQL
        SELECT ev_type, ev_extra1
        FROM #{table}
        GROUP BY ev_type, ev_extra1 ORDER BY ev_extra1, ev_type
      SQL
    end
    
    stats.each do |x|
      result["#{x['ev_extra1']}:#{x['ev_type']}"] = x['count'].to_i
    end

    result
  end
  
  
  # == proxing method for tests
  def proxy(method_name)
    self.should_receive(:enqueue) do |method_name, *data|
      x = self.coder.load(self.coder.dump(data))
      self.new.send(:perform, method_name, *x)
    end.any_number_of_times
  end
  
  # == resend failed events in queue
  def retry_failed_events(queue_name, limit = 5_000)
    database.pgq_mass_retry_failed_events(queue_name, self.consumer_name, limit)
  end
  
  def delete_failed_events(queue_name, limit = 5_000)
    database.pgq_mass_delete_failed_events(queue_name, self.consumer_name, limit)
  end

end