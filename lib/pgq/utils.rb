module Pgq::Utils

  # == all queues for database
  def queues_list
    database.pgq_get_consumer_info.map{|x| x['queue_name']}
  end

  # == methods for migrations
  def add_queue(queue_name, consumer_name = self.consumer_name)
    database.pgq_add_queue(queue_name, consumer_name)
  end

  def remove_queue(queue_name, consumer_name = self.consumer_name)
    database.pgq_remove_queue(queue_name, consumer_name)
  end
  
  # == inspect queue
  # { type => events_count }
  def inspect_queue(queue_name)
    ticks = database.pgq_get_queue_info(queue_name)
    table = connection.select_value("SELECT queue_data_pfx as table FROM pgq.queue where queue_name = #{database.sanitize(queue_name)}")
    
    result = {}
    
    if ticks['current_batch']
      sql = connection.select_value("SELECT * from pgq.batch_event_sql(#{database.sanitize(ticks['current_batch'].to_i)})")
      last_event = connection.select_value("SELECT MAX(ev_id) AS count FROM (#{sql}) AS x")
      
      stats = connection.select_all <<-SQL
        SELECT count(*) as count, ev_type
        FROM #{table}
        WHERE ev_id > #{database.sanitize(last_event.to_i)}
        GROUP BY ev_type
      SQL
      
      stats.each do |x|
        result["#{x['ev_type']}"] = x['count'].to_i
      end
      
    else    
      stats = connection.select_all <<-SQL
        SELECT ev_type
        FROM #{table}
        GROUP BY ev_type
      SQL

      stats.each do |x|
        result["#{x['ev_type']}"] = 0
      end
    end

    result
  end
  
  def inspect_self_queue
    self.inspect_queue(self.queue_name)
  end

  # show hash stats, for londiste type of storage events 
  # { type => events_count }
  def inspect_londiste_queue(queue_name)
    ticks = database.pgq_get_consumer_info
    table = connection.select_value(connection.sanitize_sql_array ["SELECT queue_data_pfx as table FROM pgq.queue where queue_name = ?", queue_name])
    
    result = {}
    
    if ticks['current_batch']
      sql = connection.select_value("SELECT * from pgq.batch_event_sql(#{database.sanitize(ticks['current_batch'].to_i)})")
      last_event = connection.select_value("SELECT MAX(ev_id) AS count FROM (#{sql}) AS x")
      
      stats = connection.select_all <<-SQL
        SELECT count(*) as count, ev_type, ev_extra1
        FROM #{table}
        WHERE ev_id > #{database.sanitize(last_event.to_i)}
        GROUP BY ev_type, ev_extra1
      SQL
      
      stats.each do |x|
        result["#{x['ev_extra1']}:#{x['ev_type']}"] = x['count'].to_i
      end
      
    else    
      stats = connection.select_all <<-SQL
        SELECT ev_type, ev_extra1
        FROM #{table}
        GROUP BY ev_type, ev_extra1 ORDER BY ev_extra1, ev_type
      SQL

      stats.each do |x|
        result["#{x['ev_extra1']}:#{x['ev_type']}"] = 0
      end
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
  def resend_failed_events(queue_name, limit = 5_000)
    events = database.pgq_failed_event_list(queue_name, self.consumer_name, limit, nil, 'asc') || []

    events.each do |event|
      database.pgq_failed_event_retry(queue_name, self.consumer_name, event['ev_id'])
    end
    
    events.length  
  end
  
  def clear_failed_events(queue_name, limit = 5_000)
    events = database.pgq_failed_event_list(queue_name, self.consumer_name, limit, nil, 'asc') || []
       
    events.each do |event|
      database.pgq_failed_event_delete(queue_name, self.consumer_name, event['ev_id'])
    end
                      
    events.length
  end

end