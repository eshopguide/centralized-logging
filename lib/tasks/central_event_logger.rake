# frozen_string_literal: true

require "yaml"

namespace :central_event_logger do
  desc "Add reporting database configuration to database.yml"
  task :setup_reporting_db do
    database_yml = Rails.root.join("config", "database.yml")
    if File.exist?(database_yml)
      config = YAML.load_file(database_yml)

      %w[development test production].each do |env|
        next unless config[env]

        # Preserve the existing configuration, including default imports
        primary_config = config[env]

        # Create the new structure with primary and reporting
        config[env] = {
          "primary" => primary_config,
          "reporting" => {
            "<<" => "*default", # Add the default import for reporting
            "url" => "<%= ENV['REPORTING_DATABASE_URL'] %>",
            "database_tasks" => false
          }
        }
      end

      File.open(database_yml, "w") do |file|
        file.puts config.to_yaml
      end
      puts "Reporting database configuration added to database.yml for all environments"
    else
      puts "config/database.yml not found. Please add the reporting database configuration manually."
    end
  end
end
