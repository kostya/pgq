class Pgq::Event
  attr_reader :type, :data, :id, :consumer

  def initialize(consumer, event)
    @id = event['ev_id']
    @type = event['ev_type']
    @data = consumer.coder.load(event['ev_data']) if event['ev_data']
    @consumer = consumer
  end

  def failed!(ex)
    h = {:class => ex.class.to_s, :message => ex.message, :backtrace => ex.backtrace}
    @consumer.event_failed @id, consumer.coder.dump(h)
  end
  
  def retry!(seconds = 0)
    @consumer.event_retry(@id, seconds)
  end

  def self.exception_message(e)
    <<-EXCEPTION
Exception happend
Error occurs: #{e.class.inspect}(#{e.message})
Backtrace: #{e.backtrace.join("\n") rescue ''}
    EXCEPTION
  end

  # Prepare string with exception details
  def exception_message(e)
    <<-EXCEPTION
Exception happend
Type: #{type.inspect}
Data: #{data.inspect}
Error occurs: #{e.class.inspect}(#{e.message})
Backtrace: #{e.backtrace.join("\n") rescue ''}
    EXCEPTION
  end

end