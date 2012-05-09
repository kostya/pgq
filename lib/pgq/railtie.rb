if defined?(Rails) && defined?(::Rails::Engine)

  class Pgq::Engine < ::Rails::Engine
    rake_tasks do
#      load File.dirname(__FILE__) + "/../tasks/pgq.rake"
    end                  
  end
  
end