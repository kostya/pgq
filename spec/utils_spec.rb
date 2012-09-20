require File.dirname(__FILE__) + '/spec_helper'

describe Pgq::Utils do
  after :each do
    Pgq::Consumer.remove_queue :hoho
  end
  
  it "queues list" do
    Pgq::Consumer.queues_list.sort.should == %w{bla test}.sort
    
    Pgq::Consumer.add_queue :hoho
    Pgq::Consumer.queues_list.sort.should == %w{bla test hoho}.sort
  end
end
