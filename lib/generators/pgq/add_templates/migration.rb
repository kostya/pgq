class Create<%= name_c %>Queue < ActiveRecord::Migration
  def self.up
    Pgq::Consumer.add_queue :<%= name %>
  end

  def self.down
    Pgq::Consumer.remove_queue :<%= name %>
  end
end
