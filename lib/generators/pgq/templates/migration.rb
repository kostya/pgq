class Create<%= class_name %>Queue < ActiveRecord::Migration
  def self.up
    Pgq::Consumer.add_queue :<%= file_path %>
  end

  def self.down
    Pgq::Consumer.remove_queue :<%= file_path %>
  end
end
