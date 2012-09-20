require File.dirname(__FILE__) + '/spec_helper'

describe Pgq::Api do
  before :each do
    re_queues
  end
  
  after :each do
    stop_ticker rescue nil
  end

  it "should insert event" do
    x = ActiveRecord::Base.pgq_insert_event('bla', 'tp', '1,2,3', '5,6,7')
    x.should > 0
  end
  
  it "consuming" do
    ActiveRecord::Base.pgq_insert_event('bla', 'tp', '1,2,3', '5,6,7')

    bid, events = api_extract_batch('bla')
    
    events.size.should == 1
    event = events.first
    
    event['ev_extra1'].should == '5,6,7'
    event['ev_type'].should == 'tp'
    event['ev_id'].to_i.should >= 1
    event['ev_data'].should == '1,2,3'
  end
  
  it "failed event and retry" do
    ActiveRecord::Base.pgq_failed_event_count('bla', 'default').should == 0
    ActiveRecord::Base.pgq_failed_event_list('bla', 'default').should == []

    ActiveRecord::Base.pgq_insert_event('bla', 'tp', '1,2,3', '5,6,7')

    bid, events = api_extract_batch('bla')
    
    ActiveRecord::Base.pgq_event_failed(bid, events[0]['ev_id'], 'aaa')

    ActiveRecord::Base.pgq_finish_batch(bid)

    ActiveRecord::Base.pgq_force_tick('bla')
    ActiveRecord::Base.pgq_failed_event_count('bla', 'default').should == 1
    # ActiveRecord::Base.pgq_failed_event_list('bla', 'default').should == [...]
  end
  
end