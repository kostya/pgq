# for Rails 2
if defined?(Rails) && Rails::VERSION::MAJOR == 2

module Pgq

  class PgqGenerator < Rails::Generator::NamedBase
    def manifest
      record do |m|
        m.template "pgq_class.rb", "app/workers/pgq_#{file_path}.rb"
        m.directory "spec/workers"
        m.template "spec.rb", "spec/workers/pgq_#{file_path}_spec.rb"
        m.template "migration.rb", "db/migrate/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_create_#{file_path}_queue.rb"
      end
      
      add_to_queues_list
    end
    
  private
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
  end

end

end