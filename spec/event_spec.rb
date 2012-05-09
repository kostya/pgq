require File.dirname(__FILE__) + '/spec_helper'

describe Pgq::Event do
  before :each do
    kl = Class.new(Pgq::ConsumerGroup) do
    end
    @consumer = kl.new
    @consumer.stub!(:get_next_batch).and_return ''
    @consumer.stub!(:finish_batch).and_return ''
    @coder = @consumer.coder

    @ev = Pgq::Event.new(@consumer, {'ev_type' => 'haha', 'ev_data' => @coder.dump('aaaaaaa'), 'ev_id' => 123})
  end

  it "parse data" do
    @ev.type.should == 'haha'
    @ev.data.should == 'aaaaaaa'
    @ev.id.should == 123
    @ev.consumer.should == @consumer
  end

  it "should failed!" do
    @consumer.should_receive(:event_failed).with(123, an_instance_of(String))
    @ev.failed!
  end

  it "should retry!" do
    @consumer.should_receive(:event_retry).with(123)    
    @ev.retry!
  end
 
end