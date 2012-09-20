require 'yaml'

file = File.join(File.dirname(__FILE__), %w{.. app config database.yml})
cfg = YAML.load_file(file)

ActiveRecord::Base.establish_connection cfg['test']

def re_queues
  Pgq::Consumer.remove_queue(:bla) rescue nil
  Pgq::Consumer.remove_queue(:test) rescue nil

  Pgq::Consumer.add_queue :bla
  Pgq::Consumer.add_queue :test
end

re_queues

class PgqBla < Pgq::Consumer
end

class PgqTest < Pgq::Consumer
end

class PgqHaha < Pgq::Consumer
    
  def ptest2(a, b)
    $a = a
    $b = b
    10
  end
  
end

def start_ticker
  conf = "#{ENV['RAILS_ROOT']}/config/pgq_#{ENV['RAILS_ENV']}.ini"
  output = `which pgqadm.py && pgqadm.py #{conf} -d ticker 2>&1 || which pgqadm && pgqadm #{conf} -d ticker 2>&1`
end

def stop_ticker
  conf = "#{ENV['RAILS_ROOT']}/config/pgq_#{ENV['RAILS_ENV']}.ini"
  output = `which pgqadm.py && pgqadm.py #{conf} -s 2>&1 || which pgqadm && pgqadm #{conf} -s 2>&1`
end

def api_extract_batch(queue_name, consumer_name = 'default')
  start_ticker
  bid = nil
  events = []
  count = 0
  
  loop do
    100.times{ ActiveRecord::Base.pgq_force_tick(queue_name) }
    
    bid = ActiveRecord::Base.pgq_next_batch(queue_name, consumer_name)
    
    if bid
      events = ActiveRecord::Base.pgq_get_batch_events(bid)
      if events.present?
        break 
      end
    end
    
    count += 1
    raise "count > 100" if count > 100
  end

  return [bid, events]

ensure
  stop_ticker
end