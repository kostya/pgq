require 'logger'

class Pgq::Worker
  attr_reader :logger, :queues, :consumers, :sleep_time, :watch_file
  
  def self.predict_queue_class(queue)
    klass = nil
    unless klass
      queue.to_s.match(/([a-z_]+)/i)
      klass_s = $1.to_s
      klass_s.chop! if klass_s.size > 0 && klass_s[-1].chr == '_'
      klass_s = "pgq_" + klass_s unless klass_s.start_with?("pgq_")
      klass = klass_s.camelize.constantize rescue nil
      klass = nil unless klass.is_a?(Class)
    end    
    klass    
  end

  def self.connection(queue)
    klass = predict_queue_class(queue)
    if klass
      klass.connection
    else
      raise "can't find klass for queue #{queue}"
    end
  end

  def initialize(h)
    @logger = h[:logger] || (defined?(Rails) && Rails.logger) || Logger.new(STDOUT)
    @consumers = []
    
    @queues = h[:queues]
    raise "Queue not selected" if @queues.blank?
    
    if @queues == ['all'] || @queues == 'all'
      if h[:queues_list]
        @queues = YAML.load_file(h[:queues_list])
      elsif defined?(Rails) && File.exists?(Rails.root + "config/queues_list.yml")
        @queues = YAML.load_file(Rails.root + "config/queues_list.yml")
      else
        raise "You shoud create config/queues_list.yml for all queues"
      end
    end
    
    @queues = @queues.split(',') if @queues.is_a?(String)
    
    @queues.each do |queue|
      klass = Pgq::Worker.predict_queue_class(queue)
      if klass
        @consumers << klass.new(@logger, queue)
      else
        raise "Unknown queue: #{queue}"
      end
    end

    @watch_file = h[:watch_file]
    @sleep_time = h[:sleep_time] || 0.5
  end

  def process_batch
    process_count = 0

    @consumers.each do |consumer|
      process_count += consumer.perform_batch

      if @watch_file && File.exists?(@watch_file)
        logger.info "Found file #{@watch_file}, exiting!"
        File.unlink(@watch_file)
        return processed_count
      end
    end

    process_count
  end

  def run
    logger.info "Worker for (#{@queues.join(",")}) started"

    loop do
      processed_count = process_batch
      sleep(@sleep_time) if processed_count == 0
    end
  end

end