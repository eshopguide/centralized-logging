## Usage

1. **Add the Gem to Your Gemfile**: Include the gem in your application's Gemfile by referencing the GitHub repository, and then run `bundle install`.

   ```ruby
   gem 'central_event_logger', git: 'https://github.com/eshopguide/centralized-logging.git'
   ```

2. **Set Up Reporting Database Configuration**: Run the Rake task to set up the reporting database configuration in your `config/database.yml` file.

   ```bash
   rails central_event_logger:setup_reporting_db
   ```

   This task will modify your `config/database.yml` file to include the reporting database configuration for all environments (development, test, and production). It will preserve existing configurations and add the reporting database as a secondary database.

   After running this task, your `database.yml` will have a structure similar to this for each environment:

   ```yaml
   environment_name:
     primary:
       # Your existing database configuration
     reporting:
       <<: *default
       url: <%= ENV['REPORTING_DATABASE_URL'] %>
       database_tasks: false
   ```

   Make sure to review the changes in your `config/database.yml` file after running the task.

3. **Set Environment Variables**: Ensure the following environment variables are set in your environment:

   - `REPORTING_DATABASE_URL`: The connection string for your reporting database.
   - `APP_NAME`: A unique identifier for your application.

   You can set these in a `.env` file for local development:

   ```
   REPORTING_DATABASE_URL=postgres://username:password@host:port/database_name
   APP_NAME=YourAppName
   ```

4. **Verify Configuration**: Check that the `config/database.yml` file includes the reporting database configuration using the environment variable.

5. **Use the Gem**: You can now use the `CentralEventLogger` to log events to your reporting database. Here's an example of how to use the `log_event` method:

   ```ruby
   CentralEventLogger.log_event(
     event_name: attribute,
     event_type: CentralEventLogger::EventTypes::SETTINGS_CHANGE,
     customer_myshopify_domain: self&.shop&.shopify_domain,
     event_value: changes.last,
     payload: { from: changes.first, to: changes.last },
     app_name: CentralEventLogger.configuration.app_name
   )
   ```

   This example shows logging a settings change event. The parameters are:
   - `event_name`: The name of the event (in this case, the attribute that changed)
   - `event_type`: The type of event (using a predefined constant from `CentralEventLogger::EventTypes`)
   - `customer_myshopify_domain`: The Shopify domain of the customer (if applicable)
   - `event_value`: The new value after the change
   - `payload`: Additional information about the event (in this case, the old and new values)
   - `app_name`: The name of your application (retrieved from the configuration)

   Make sure to adjust the parameters according to the event you're logging and the data available in your context.

By following these steps, you can integrate the `CentralEventLogger` gem into your Rails application and start logging events to a centralized database.
