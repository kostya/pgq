require File.dirname(__FILE__) + '/spec_helper'

class PgqGr < Pgq::ConsumerGroup
  def perform_group opts; end
  def hahah; end
  def bla; end
end

describe Pgq::ConsumerGroup do
  before :each do
    @consumer = PgqGr.new
    @consumer.stub!(:get_next_batch).and_return ''
    @consumer.stub!(:finish_batch).and_return ''
    @coder = @consumer.coder
  end

  it "queue_name" do
    PgqGr.queue_name.should == 'gr'
  end

  it "should call consume" do
    @consumer.should_receive(:perform_group) do |h|
      ev1 = h['hahah']
      ev1.size.should == 2
      ev1.first.data.should == '1'
      ev1.second.data.should == '3'

      ev2 = h['bla']
      ev2.size.should == 1
      ev2.first.data.should == '2'
    end
    @consumer.should_receive(:get_batch_events).and_return([{'ev_type' => 'hahah', 'ev_data' => @coder.dump('1')}, 
      {'ev_type' => 'bla', 'ev_data' => @coder.dump('2')}, {'ev_type' => 'hahah', 'ev_data' => @coder.dump('3')}])
    @consumer.perform_batch
  end

end
