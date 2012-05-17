module Pgq::Api
  # should mixin to class, which have connection

  # == manage queues
  
  def pgq_create_queue(queue_name)
    connection.select_value(sanitize_sql_array ["SELECT pgq.create_queue(?)", queue_name]).to_i
  end

  def pgq_drop_queue(queue_name)
    connection.select_value(sanitize_sql_array ["SELECT pgq.drop_queue(?)", queue_name]).to_i
  end

  def pgq_register_consumer(queue_name, consumer_name)
    connection.select_value(sanitize_sql_array ["SELECT pgq.register_consumer(?, ?)", queue_name, consumer_name]).to_i
  end

  def pgq_unregister_consumer(queue_name, consumer_name)
    connection.select_value(sanitize_sql_array ["SELECT pgq.unregister_consumer(?, ?)", queue_name, consumer_name]).to_i
  end
  
  # == insert events

  def pgq_insert_event(queue_name, ev_type, ev_data, ev_extra1 = nil, ev_extra2 = nil, ev_extra3 = nil, ev_extra4 = nil)
    result = connection.select_value(sanitize_sql_array ["SELECT pgq.insert_event(?, ?, ?, ?, ?, ?, ?)", 
                                                         queue_name, ev_type, ev_data, ev_extra1, ev_extra2, ev_extra3, ev_extra4])
    result ? result.to_i : nil
  end
  
  # == consuming
  
  def pgq_next_batch(queue_name, consumer_name)
    result = connection.select_value(sanitize_sql_array ["SELECT pgq.next_batch(?, ?)", queue_name, consumer_name])
    result ? result.to_i : nil
  end
  
  def pgq_get_batch_events(batch_id)
    connection.select_all(sanitize_sql_array ["SELECT * FROM pgq.get_batch_events(?)", batch_id])
  end
  
  def pgq_finish_batch(batch_id)
    connection.select_value(sanitize_sql_array ["SELECT pgq.finish_batch(?)", batch_id])
  end
  
  # == failed/retry
  
  def pgq_event_failed(batch_id, event_id, reason)
    connection.select_value(sanitize_sql_array ["SELECT pgq.event_failed(?, ?, ?)", batch_id, event_id, reason]).to_i
  end
          
  def pgq_event_retry(batch_id, event_id, retry_seconds)
    connection.select_value(sanitize_sql_array ["SELECT pgq.event_retry(?, ?, ?)", batch_id, event_id, retry_seconds]).to_i
  end                  

  # == failed events
  
  def pgq_failed_event_retry(queue_name, consumer_name, event_id)
    connection.select_value(sanitize_sql_array ["SELECT * FROM pgq.failed_event_retry(?, ?, ?)", queue_name, consumer_name, event_id])
  end
      
  def pgq_failed_event_delete(queue_name, consumer_name, event_id)
    connection.select_value(sanitize_sql_array ["SELECT * FROM pgq.failed_event_delete(?, ?, ?)", queue_name, consumer_name, event_id])
  end
     
  def pgq_failed_event_count(queue_name, consumer_name)
    res = connection.select_value(sanitize_sql_array ["SELECT * FROM pgq.failed_event_count(?, ?)", queue_name, consumer_name])
    res ? res.to_i : nil
  end
  
  def pgq_failed_event_list queue_name, consumer_name, limit = nil, offset = nil, order = 'desc'
    order = (order.to_s == 'desc') ? order : 'asc'
    connection.select_all(sanitize_sql_array ["SELECT * FROM pgq.failed_event_list(?, ?, ?, ?) ORDER BY ev_id #{order.upcase}", queue_name, consumer_name, limit.to_i, offset.to_i])
  end

  # == info methods

  def pgq_get_queue_info(queue_name)
    connection.select_value(sanitize_sql_array ["SELECT pgq.get_queue_info(?)", queue_name])
  end          
  
  # Get list of queues.
  # Result: (queue_name, queue_ntables, queue_cur_table, queue_rotation_period, queue_switch_time, queue_external_ticker, queue_ticker_max_count, queue_ticker_max_lag, queue_ticker_idle_period, ticker_lag)
  def pgq_get_queues_info
    connection.select_values("SELECT pgq.get_queue_info()")
  end          
  
  def pgq_get_consumer_info
    connection.select_all("SELECT *, EXTRACT(epoch FROM last_seen) AS last_seen_sec, EXTRACT(epoch FROM lag) AS lag_sec FROM pgq.get_consumer_info()")
  end
  
  def pgq_get_consumer_queue_info(queue_name)
    connection.select_one(sanitize_sql_array ["SELECT *, EXTRACT(epoch FROM last_seen) AS last_seen_sec, EXTRACT(epoch FROM lag) AS lag_sec FROM pgq.get_consumer_info(?)", queue_name]) || {}
  end

  # == utils
  
  def pgq_last_event_id(queue_name)
    ticks = pgq_get_consumer_queue_info(queue_name)
    table = connection.select_value("SELECT queue_data_pfx AS table FROM pgq.queue WHERE queue_name = #{sanitize(queue_name)}")

    result = nil

    if ticks['current_batch']
      sql = connection.select_value("SELECT * FROM pgq.batch_event_sql(#{sanitize(ticks['current_batch'].to_i)})")
      last_event = connection.select_value("SELECT MAX(ev_id) AS count FROM (#{sql}) AS x")
      result = last_event.to_i
    end

    [table, result]
  end
  
  def pgq_mass_retry_failed_events(queue_name, consumer_name, limit = 5_000)
    events = pgq_failed_event_list(queue_name, consumer_name, limit, nil, 'asc') || []

    events.each do |event|
      pgq_failed_event_retry(queue_name, consumer_name, event['ev_id'])
    end

    events.length
  end

  def pgq_mass_delete_failed_events(queue_name, consumer_name, limit = 5_000)
    events = pgq_failed_event_list(queue_name, consumer_name, limit, nil, 'asc') || []

    events.each do |event|
      pgq_failed_event_delete(queue_name, consumer_name, event['ev_id'])
    end

    events.length
  end

end