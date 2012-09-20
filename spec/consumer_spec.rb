require File.dirname(__FILE__) + '/spec_helper'

describe PgqHaha do
  before :each do
    @consumer = PgqHaha.new
    @coder = @consumer.coder
    @data = [1,2,[3,4], nil]

    @consumer.stub!(:get_next_batch).and_return ''
    @consumer.stub!(:finish_batch).and_return ''
  end

  it "queue name" do
    @consumer.queue_name.should == 'haha'
  end

  it "missing method should insert event" do
    PgqHaha.should_receive(:enqueue).with(:bla, 1,2,[3,4], nil)
    PgqHaha.bla 1, 2, [3, 4], nil
  end

  it "should enqueue with add_event" do
    PgqHaha.should_receive(:enqueue).with(:bla, 1,2,[3,4], nil)
    PgqHaha.add_event :bla, 1, 2, [3, 4], nil
  end

  it "magick perform" do
    @consumer.should_receive(:bla) do |*h|
      h.should == @data
    end

    @consumer.should_receive(:get_batch_events).and_return([{'ev_type' => 'bla', 'ev_data' => @coder.dump(@data)}])
    @consumer.perform_batch
  end
  
  it "should proxy consumer" do
    PgqHaha.proxy(:ptest2)
    PgqHaha.ptest2(111, 'abc').should == 10
    $a.should == 111
    $b.should == 'abc'
  end
  
end
