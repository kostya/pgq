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
