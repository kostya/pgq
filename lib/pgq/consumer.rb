require 'pgq/consumer_base'

# Cute class, for magick inserts and light consume

class Pgq::Consumer < Pgq::ConsumerBase
  
  # == magick insert events
 
  def self.method_missing(method_name, *args)
    enqueue(method_name, *args)
  end
  
  def self.add_event(method_name, *args)
    enqueue(method_name, *args)
  end

  # == magick consume

  def perform(method_name, *args)
    self.send(method_name, *args)
  end

end