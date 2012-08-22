require 'active_support'
require 'active_record'
require 'marshal64'

module Pgq
end

Dir[File.dirname(__FILE__) + "/pgq/*.rb"].each{|f| require f }

ActiveRecord::Base.extend(Pgq::Api) if defined?(ActiveRecord::Base)
