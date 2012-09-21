# for Rails 3
if defined?(Rails) && Rails::VERSION::MAJOR >= 3

module Pgq
  class AddGenerator < Rails::Generators::NamedBase
    include Rails::Generators::Migration
    source_root File.expand_path("../templates", __FILE__)
    
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
      template "pgq_class.rb", "app/workers/pgq_#{file_path}.rb"
      template "spec.rb", "spec/workers/pgq_#{file_path}_spec.rb"
      migration_template "migration.rb", "db/migrate/create_#{file_path}_queue.rb"
    end
  end
  
end

end