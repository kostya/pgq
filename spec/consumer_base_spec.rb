require File.dirname(__FILE__) + '/spec_helper'

class PgqTata < Pgq::ConsumerBase
end

class PgqTata2 < Pgq::ConsumerBase
  @queue_name = "huhu"
end

class PgqTata3 < Pgq::ConsumerBase
  set_queue_name 'hehu'  

  def self.next_queue_name
    'tutturu'
  end
  
  def perform(name, a, b)
    $a = a
    $b = b
    10
  end
 
end

describe Pgq::ConsumerBase do
  before :each do
    @consumer = PgqTata.new
    @consumer2 = PgqTata2.new
    @consumer3 = PgqTata3.new

    @coder = @consumer.coder
  end

  it "queue_name" do
    PgqTata.queue_name.should == 'tata'
    @consumer.queue_name.should == 'tata'

    PgqTata2.queue_name.should == 'huhu'
    @consumer2.queue_name.should == 'huhu'

    PgqTata3.queue_name.should == 'hehu'
    @consumer3.queue_name.should == 'hehu'
  end

  it "default encode/decode" do
    data = {:a => [1, 2, 3, {:b => 'c'}]}
    s = @coder.dump(data)
    @coder.load(s).should == data
  end

  it "enqueue all cases" do
    PgqTata.database.should_receive(:pgq_insert_event).with('tata', 'method1', @coder.dump([1,2,3]))
    PgqTata.enqueue(:method1, 1, 2, 3)

    PgqTata2.database.should_receive(:pgq_insert_event).with('huhu', 'method1', @coder.dump([[1,2,3]]))
    PgqTata2.enqueue(:method1, [1, 2, 3]) 

    PgqTata3.database.should_receive(:pgq_insert_event).with('tutturu', 'method1', @coder.dump([]))
    PgqTata3.enqueue(:method1) 
  end


  describe "consuming" do
    before :each do
      @data = [1, 2, 3]
      @event = {'ev_type' => 'bla', 'ev_data' => @coder.dump(@data)}
    end

    it "perform_batch should_receive perform_events" do
      @consumer.should_receive(:get_batch_events).and_return([@event])
      @consumer.should_not_receive(:all_events_failed)
      @consumer.should_receive(:perform_events) do |events|
        events.size.should == 1
        ev = events.first
        ev.type.should == 'bla'
        ev.data.should == @data
      end
      @consumer.should_receive(:finish_batch).with(1)
      @consumer.perform_batch.should == 1
    end

    it "perform_batch raises" do
      @consumer.should_receive(:get_batch_events).and_return([@event])
      @consumer.should_receive(:perform_events).and_raise(:wow)
      @consumer.should_receive(:all_events_failed)
      @consumer.should_receive(:finish_batch).with(1)
      @consumer.perform_batch.should == 1
    end

    it "perform_batch empty" do
      @consumer.should_receive(:get_batch_events).and_return([])
      @consumer.should_not_receive(:all_events_failed)
      @consumer.should_not_receive(:perform_events)
      @consumer.should_receive(:finish_batch).with(0)
      @consumer.perform_batch.should == 0
    end

  end

  describe "actions with events" do
    before :each do
      @data = [1, 2, 3]
      @event = Pgq::Event.new(@consumer, {'ev_type' => 'bla', 'ev_data' => @coder.dump(@data)})
      @events = [@event]      
    end

    it "all_events_failed" do
      ex = Exception.new('wow')
      @event.should_receive(:failed!).with(ex)
      @consumer.all_events_failed(@events, ex)
    end

    it "perform_events" do
      @consumer.should_receive(:perform_event).with(@event)
      @consumer.perform_events(@events)
    end

    it "perform_event ok" do
      @consumer.should_receive(:perform).with('bla', *@data)
      @consumer.perform_event(@event)
    end

    it "perform_event raised" do
      ex = Exception.new('wow')
      @consumer.should_receive(:perform).with('bla', *@data).and_raise(ex)
      @event.should_receive(:failed!).with(ex)
      @consumer.perform_event(@event)
    end

  end

  describe "migration" do
    it "up" do
      Pgq::ConsumerBase.database.should_receive(:pgq_create_queue).with('super')
      Pgq::ConsumerBase.database.should_receive(:pgq_register_consumer).with('super', Pgq::ConsumerBase.consumer_name)
      Pgq::ConsumerBase.add_queue("super")
    end

    it "down" do
      Pgq::ConsumerBase.database.should_receive(:pgq_drop_queue).with('super')
      Pgq::ConsumerBase.database.should_receive(:pgq_unregister_consumer).with('super', Pgq::ConsumerBase.consumer_name)
      Pgq::ConsumerBase.remove_queue("super")
    end
  end
  
  it "should proxy consumer" do
    PgqTata3.proxy(:ptest)
    PgqTata3.enqueue(:ptest, 111, 'abc').should == 10
    $a.should == 111
    $b.should == 'abc'
  end

end