class Pgq::Event
  attr_reader :type, :data, :id, :consumer

  def initialize(consumer, event)
    @id = event['ev_id']
    @type = event['ev_type']
    @data = consumer.coder.load(event['ev_data']) if event['ev_data']
    @consumer = consumer
  end

  def failed!(ex = 'Something happens')
    if ex.is_a?(String)
      @consumer.event_failed @id, ex
    else # exception
      @consumer.event_failed @id, exception_message(ex)      
    end
  end
  
  def retry!
    @consumer.event_retry(@id)
  end

  def self.exception_message(e)
    <<-EXCEPTION
Exception happend
Type: #{e.class.inspect}
Error occurs: #{e.message}
Backtrace: #{e.backtrace.join("\n") rescue ''}
    EXCEPTION
  end

  # Prepare string with exception details
  def exception_message(e)
    <<-EXCEPTION
Exception happend
Type: #{type.inspect} #{e.class.inspect}
Data: #{data.inspect}
Error occurs: #{e.message}
Backtrace: #{e.backtrace.join("\n") rescue ''}
    EXCEPTION
  end

end