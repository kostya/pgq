[pgqadm]
job_name = pgqadm_<%= env_name %>
db = dbname=dbname user=user password=password host=127.0.0.1 port=5432

# how often to run maintenance [seconds]
maint_delay = 600

# how often to check for activity [seconds]
loop_delay = 0.1

logfile = log/%(job_name)s.log
pidfile = tmp/%(job_name)s.pid
