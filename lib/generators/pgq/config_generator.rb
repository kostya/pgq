module Pgq
  class ConfigGenerator < Rails::Generators::Base
    source_root File.expand_path("../config_templates", __FILE__)
    
    def copy_configs
      self.env_name = 'development'
      template "pgq.rb", "config/pgq_development.ini"
      self.env_name = 'test'
      template "pgq.rb", "config/pgq_test.ini"
      self.env_name = 'production'
      template "pgq.rb", "config/pgq_production.ini"
    end
    
  private  
    attr_accessor :env_name
    
  end
end