require 'pgq/utils'
require 'pgq/api'
require 'active_support/inflector' unless ''.respond_to?(:underscore)
require 'logger'

class Pgq::ConsumerBase
  extend Pgq::Utils

  @queue_name = 'default'
  @consumer_name = 'default'
  
  attr_accessor :logger, :queue_name, :consumer_name

  # == connection 

  def self.database
    ActiveRecord::Base # can redefine
  end
  
  def database
    self.class.database
  end
  
  def self.connection
    database.connection
  end
  
  def connection
    self.class.connection
  end

  # == queue name
  
  def self.extract_queue_name
    self.name.to_s.gsub(/^pgq/i, '').underscore.gsub('/', '-')
  end
  
  def self.set_queue_name(name)
    @queue_name = name.to_s
  end
  
  # magic set queue_name from class name
  def self.inherited(subclass)
    subclass.set_queue_name(subclass.extract_queue_name)
    subclass.instance_variable_set('@consumer_name', self.consumer_name)
  end

  def self.consumer_name
    @consumer_name
  end

  def self.queue_name
    @queue_name
  end

  # this method used when insert event, possible to reuse
  def self.next_queue_name
    self.queue_name
  end

  # == coder

  def self.coder
    Marshal64
  end
  
  def coder
    self.class.coder
  end

  # == insert event
  
  def self.enqueue_to(queue_name, method_name, *args)
    self.database.pgq_insert_event( queue_name, method_name.to_s, coder.dump(args) )
  end

  def self.enqueue(method_name, *args)
    self.database.pgq_insert_event( self.next_queue_name, method_name.to_s, coder.dump(args) )
  end
  
  # == consumer part
  
  def initialize(logger = nil, custom_queue_name = nil, custom_consumer_name = nil)
    self.queue_name = custom_queue_name || self.class.queue_name
    self.consumer_name = custom_consumer_name || self.class.consumer_name
    self.logger = logger || Logger.new(nil)
    @batch_id = nil
  end
  
  def perform_batch
    events = []
    pgq_events = get_batch_events

    return 0 if pgq_events.blank?
    
    events = pgq_events.map{|ev| Pgq::Event.new(self, ev) }
    size = events.size
    log_info "=> batch(#{queue_name}): events #{size}"
    
    perform_events(events)
    
  rescue Exception => ex
    all_events_failed(events, ex)
 
  rescue => ex
    all_events_failed(events, ex)
    
  ensure
    finish_batch(events.size)
    
    return events.size
  end
  
  def perform_events(events)
    events.each do |event|
      perform_event(event)
    end
  end

  def perform_event(event)
    type = event.type
    data = event.data

    perform(type, *data)

  rescue Exception => ex
    self.log_error(event.exception_message(ex))
    event.failed!(ex)
    
  rescue => ex
    self.log_error(event.exception_message(ex))
    event.failed!(ex)
  end

  def perform(type, *data)
    raise "realize me"    
  end

  def get_batch_events
    @batch_id = database.pgq_next_batch(queue_name, consumer_name)
    return nil if !@batch_id
    database.pgq_get_batch_events(@batch_id)
  end

  def finish_batch(count = nil)
    return unless @batch_id
    database.pgq_finish_batch(@batch_id)
    @batch_id = nil
  end
  
  def event_failed(event_id, reason)
    database.pgq_event_failed(@batch_id, event_id, reason)
  end

  def event_retry(event_id, seconds = 0)
    database.pgq_event_retry(@batch_id, event_id, seconds)
  end

  def all_events_failed(events, ex)
    log_error(Pgq::Event.exception_message(ex))
    
    events.each do |event|
      event.failed!(ex)
    end    
  end

  # == log methods

  def log_info(mes)
    @logger.info(mes) if @logger
  end

  def log_error(mes)
    @logger.error(mes) if @logger
  end
  
end
