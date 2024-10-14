## Usage

1. **Add the Gem to Your Gemfile**: Include the gem in your application's Gemfile and run `bundle install`.

   ```ruby
   gem 'central_event_logger'
   ```

2. **Run the Generator**: Use the Rails generator to set up the reporting database configuration.

   ```bash
   rails generate central_event_logger:install
   ```

   This will append the necessary configuration to your `config/database.yml` file.

3. **Set Environment Variables**: Ensure the following environment variables are set in your environment:

   - `REPORTING_DATABASE_URL`: The connection string for your reporting database.
   - `APP_NAME`: A unique identifier for your application.

   You can set these in a `.env` file for local development:

   ```
   REPORTING_DATABASE_URL=postgres://username:password@host:port/database_name
   APP_NAME=YourAppName
   ```

4. **Verify Configuration**: Check that the `config/database.yml` file includes the reporting database configuration using the environment variable.

5. **Use the Gem**: You can now use the `CentralEventLogger` to log events to your reporting database.

   ```ruby
   CentralEventLogger.log_event(
     event_name: "user_signed_in",
     event_type: "authentication",
     customer_id: 123
   )
   ```

By following these steps, you can integrate the `CentralEventLogger` gem into your Rails application and start logging events to a centralized database.