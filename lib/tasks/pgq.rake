if defined?(Rails)
  ENV['RAILS_ROOT'] ||= Rails.root
  ENV['RAILS_ENV'] ||= Rails.env
end

namespace :pgq do

  desc "Start worker params: QUEUES, LOGGER, WATCH_FILE"
  task :worker => [:environment] do 
    queues = ENV['QUEUES']
    logger_file = ENV['LOGGER'] || "#{ENV['RAILS_ROOT']}/log/pgq_#{queues}.log"
    watch_file = ENV['WATCH_FILE'] || "#{ENV['RAILS_ROOT']}/tmp/pgq_#{queues}.stop"
    logger = Logger.new(logger_file)
    w = Pgq::Worker.new(:logger => logger, :queues => queues, :watch_file => watch_file)
    w.run
  end

  desc "Install PgQ to database RAILS_ENV"
  task :install do
    Dir["#{ENV['RAILS_ROOT']}/config/pgq_#{ENV['RAILS_ENV']}*.ini"].each do |conf|
      ENV['PGQFILE']=conf
      Rake::Task['pgq:install_from_file'].invoke
    end
  end

  desc "Install PgQ from file ENV['PGQFILE'] to database RAILS_ENV"
  task :install_from_file do
    puts "No file specified" and return if !ENV['PGQFILE'] || ENV['PGQFILE'].empty?

    conf = ENV['PGQFILE']
    
    puts "installing pgq, running: pgqadm.py #{conf} install"

    output = `which pgqadm.py && pgqadm.py #{conf} install 2>&1 || which pgqadm && pgqadm #{conf} install 2>&1`
    puts output
    if output =~ /pgq is installed/ || output =~ /Reading from.*?pgq.sql$/
      puts "PgQ installed successfully"
    else
      raise "Something went wrong(see above)... Check that you install skytools package and create #{conf}"
    end
  end

  desc "Generate Pgq config from database.yml and RAILS_ENV"
  task :generate_config do
    require 'yaml'
    raise "RAILS_ROOT should be" unless ENV['RAILS_ROOT']
    raise "RAILS_ENV should be" unless ENV['RAILS_ENV']
    
    cfg = if ENV['DATABASE_YML']
      YAML.load_file(ENV['DATABASE_YML']) if File.exists?(ENV['DATABASE_YML'])
    else
      file = File.join(ENV['RAILS_ROOT'], %w{config database.yml})
      YAML.load_file(file) if File.exists?(file)
    end
    
    raise "Not found database.yml" unless cfg
    cfg = cfg[ ENV["RAILS_ENV"] ]
  
    pgq_config = <<-SQL
[pgqadm]
job_name = #{cfg['database']}_pgqadm
db = host=#{cfg['host'] || '127.0.0.1'} dbname=#{cfg['database']} user=#{cfg['username']} password=#{cfg['password']} port=#{cfg['port'] || 5432}
maint_delay = 500
loop_delay = 0.05
logfile = log/%(job_name)s.log
pidfile = tmp/%(job_name)s.pid
    SQL
    
    output = ENV["PGQ_CONFIG"] || File.join(ENV["RAILS_ROOT"], ["config", "pgq_#{ENV["RAILS_ENV"]}.ini"])
    File.open(output, 'w'){|f| f.write(pgq_config) }
    puts "Config #{ENV["RAILS_ENV"]} generated to '#{output}'"
  end  
  
  
  namespace :ticker do
  
    desc "Start PgQ ticker daemon"
    task :start do
      conf = "#{ENV['RAILS_ROOT']}/config/pgq_#{ENV['RAILS_ENV']}.ini"
      output = `which pgqadm.py && pgqadm.py #{conf} -d ticker 2>&1 || which pgqadm && pgqadm #{conf} -d ticker 2>&1`
      if output.empty?
        puts "ticker daemon started"
      else
        puts output
      end
    end
  
    desc "Stop PgQ ticker daemon"
    task :stop do
      conf = "#{ENV['RAILS_ROOT']}/config/pgq_#{ENV['RAILS_ENV']}.ini"
      output = `which pgqadm.py && pgqadm.py #{conf} -s 2>&1 || which pgqadm && pgqadm #{conf} -s 2>&1`
      if output.empty?
        puts "ticker daemon stoped"
      else
        puts output
      end
    end
  
  end
end