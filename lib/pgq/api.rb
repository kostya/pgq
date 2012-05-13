module Pgq::Api
  # should mixin to class, which have connection

  def pgq_create_queue(queue_name)
    connection.select_value(sanitize_sql_array ["SELECT pgq.create_queue(?)", queue_name]).to_i
  end

  def pgq_drop_queue(queue_name)
    connection.select_value(sanitize_sql_array ["SELECT pgq.drop_queue(?)", queue_name]).to_i
  end

  def pgq_register_consumer(queue_name, consumer_id)
    connection.select_value(sanitize_sql_array ["SELECT pgq.register_consumer(?, ?)", queue_name, consumer_id]).to_i
  end

  def pgq_unregister_consumer(queue_name, consumer_id)
    connection.select_value(sanitize_sql_array ["SELECT pgq.unregister_consumer(?, ?)", queue_name, consumer_id]).to_i
  end

  def pgq_add_queue(queue_name, consumer_name)
    pgq_create_queue(queue_name.to_s)
    pgq_register_consumer(queue_name.to_s, consumer_name.to_s)
  end

  def pgq_remove_queue(queue_name, consumer_name)
    pgq_unregister_consumer(queue_name.to_s, consumer_name.to_s)
    pgq_drop_queue(queue_name.to_s)
  end

  def pgq_insert_event(queue_name, ev_type, ev_data, ev_extra1 = nil, ev_extra2 = nil, ev_extra3 = nil, ev_extra4 = nil)
    result = connection.select_value(sanitize_sql_array ["SELECT pgq.insert_event(?, ?, ?, ?, ?, ?, ?)", 
                                                         queue_name, ev_type, ev_data, ev_extra1, ev_extra2, ev_extra3, ev_extra4])
    result ? result.to_i : nil
  end
  
  def pgq_next_batch(queue_name, consumer_id)
    result = connection.select_value(sanitize_sql_array ["SELECT pgq.next_batch(?, ?)", queue_name, consumer_id])
    result ? result.to_i : nil
  end
  
  def pgq_get_batch_events(batch_id)
    connection.select_all(sanitize_sql_array ["SELECT * FROM pgq.get_batch_events(?)", batch_id])
  end
  
  def pgq_event_failed(batch_id, event_id, reason)
    connection.select_value(sanitize_sql_array ["SELECT pgq.event_failed(?, ?, ?)", batch_id, event_id, reason]).to_i
  end
  
  def pgq_event_retry(batch_id, event_id, retry_seconds)
    connection.select_value(sanitize_sql_array ["SELECT pgq.event_retry(?, ?, ?)", batch_id, event_id, retry_seconds]).to_i
  end
  
  def pgq_finish_batch(batch_id)
    connection.select_value(sanitize_sql_array ["SELECT pgq.finish_batch(?)", batch_id])
  end

  def pgq_failed_event_retry(queue_name, consumer, event_id)
    connection.select_value(sanitize_sql_array ["SELECT * FROM pgq.failed_event_retry(?, ?, ?)", queue_name, consumer, event_id])
  end
      
  def pgq_failed_event_delete(queue_name, consumer, event_id)
    connection.select_value(sanitize_sql_array ["SELECT * FROM pgq.failed_event_delete(?, ?, ?)", queue_name, consumer, event_id])
  end
     
  def pgq_failed_event_count(queue_name, consumer)
    res = connection.select_value(sanitize_sql_array ["SELECT * FROM pgq.failed_event_count(?, ?)", queue_name, consumer])
    res ? res.to_i : nil
  end
  
  def pgq_failed_event_list queue_name, consumer, limit = nil, offset = nil, order = 'desc'
    order = (order.to_s == 'desc') ? order : 'asc'
    connection.select_all(sanitize_sql_array ["SELECT * FROM pgq.failed_event_list(?, ?, ?, ?) order by ev_id #{order}", queue_name, consumer, limit.to_i, offset.to_i])
  end

  # queue lag in seconds
  def pgq_queue_lag(queue_name)
    connection.select_value(sanitize_sql_array ["SELECT Max(EXTRACT(epoch FROM lag)) FROM pgq.get_consumer_info() where queue_name = ?", queue_name]).to_f
  end
  
  def pgq_get_queue_info(queue_name)
    connection.select_value(sanitize_sql_array ["SELECT pgq.get_queue_info(?)", queue_name])
  end          
  
  def pgq_get_queues_info()
    connection.select_all("SELECT pgq.get_queue_info()")
  end          
  
  def pgq_get_consumer_info
    connection.select_all("SELECT * FROM pgq.get_consumer_info()")
  end

end