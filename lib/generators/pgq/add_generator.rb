module Pgq
  class AddGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    source_root File.expand_path("../add_templates", __FILE__)
    argument :queue_name, :type => :string
    
    def self.next_migration_number(path)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end    

    def add_to_queues_list
      filename = Rails.root + 'config/queues_list.yml'
      if File.exists?(filename)
        x = YAML.load_file(filename)
        x << name
        File.open(filename, 'w'){|f| f.write(YAML.dump(x))}
      else
        x = [name]
        File.open(filename, 'w'){|f| f.write(YAML.dump(x))}
      end
    end
    
    def add_files
      template "pgq_class.rb", "app/models/pgq/pgq_#{name}.rb"
      template "spec.rb", "spec/models/pgq/pgq_#{name}_spec.rb"
      migration_template "migration.rb", "db/migrate/create_#{name}_queue.rb"
    end
    
  private
  
    def name 
      queue_name.underscore
    end
    
    def name_c
      name.camelize
    end
  end
  
end
