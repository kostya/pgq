require File.dirname(__FILE__) + '/spec_helper'

describe Pgq::Worker do
  it "should find class not in hash" do
    Pgq::Worker.predict_queue_class('bla').should == PgqBla
    Pgq::Worker.predict_queue_class('bla_1').should == PgqBla
    Pgq::Worker.predict_queue_class('bla_2').should == PgqBla
    Pgq::Worker.predict_queue_class('bla3').should == PgqBla
    Pgq::Worker.predict_queue_class('bla_').should == PgqBla
    Pgq::Worker.predict_queue_class('pgq_bla_22').should == PgqBla

    Pgq::Worker.predict_queue_class('blah').should == nil
    Pgq::Worker.predict_queue_class('').should == nil
    Pgq::Worker.predict_queue_class(nil).should == nil
  end

  it "initialize" do
    @w = Pgq::Worker.new :queues => ['bla']

    @w.consumers.size.should == 1
    cons = @w.consumers.first
    cons.class.should == PgqBla
    cons.queue_name.should == 'bla'
  end

  it "process_batch" do
    @w = Pgq::Worker.new :queues => ['bla']
    cons = @w.consumers.first

    cons.should_receive(:perform_batch).and_return(10)
    @w.process_batch.should == 10
  end

end
