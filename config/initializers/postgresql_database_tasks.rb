module ActiveRecord
  module Tasks
    class PostgreSQLDatabaseTasks
      def drop
      	puts "dropping database..."
        establish_master_connection
        connection.select_all "select pg_terminate_backend(pg_stat_activity.pid) from pg_stat_activity where datname='#{configuration_hash[:database]}' AND state='idle';"
        connection.drop_database configuration_hash[:database]
      end
    end
  end
end
