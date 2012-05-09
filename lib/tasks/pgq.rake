namespace :pgq do

  desc "Start worker params: QUEUES, LOGGER, WATCH_FILE"
  task :worker => [:environment] do 
    queues = ENV['QUEUES']
    logger_file = ENV['LOGGER'] || Rails.root.join("log/pgq_#{queues}.log")
    watch_file = ENV['WATCH_FILE'] || Rails.root.join("tmp/pgq_#{queues}.stop")
    logger = Logger.new(logger_file)
    w = Pgq::Worker.new(:logger => logger, :queues => queues, :watch_file => watch_file)
    w.run
  end

  desc "Install PgQ to database RAILS_ENV"
  task :install do
    Dir["#{Rails.root}/config/pgq_#{Rails.env}*.ini"].each do |conf|
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
  
  
  namespace :ticker do
  
    desc "Start PgQ ticker daemon"
    task :start do
      conf = Rails.root.join("config/pgq_#{Rails.env}.ini")
      output = `which pgqadm.py && pgqadm.py #{conf} -d ticker 2>&1 || which pgqadm && pgqadm #{conf} -d ticker 2>&1`
      if output.empty?
        puts "ticker daemon started"
      else
        puts output
      end
    end
  
    desc "Stop PgQ ticker daemon"
    task :stop do
      conf = Rails.root.join("config/pgq_#{Rails.env}.ini")
      output = `which pgqadm.py && pgqadm.py #{conf} -s 2>&1 || which pgqadm && pgqadm #{conf} -s 2>&1`
      if output.empty?
        puts "ticker daemon stoped"
      else
        puts output
      end
    end
  
  end
end