## Usage

1. **Add the Gem to Your Gemfile**: Include the gem in your application's Gemfile by referencing the GitHub repository, and then run `bundle install`.

   ```ruby
   gem 'central_event_logger', git: 'https://github.com/eshopguide/centralized-logging.git'
   ```

2. **Set Environment Variables**: Ensure the following environment variables are set in your environment:

   - `CENTRAL_EVENT_LOGGER_API_ENDPOINT`: The URL of the API endpoint for logging events.
   - `CENTRAL_EVENT_LOGGER_API_KEY`: Your API key for authentication.
   - `CENTRAL_EVENT_LOGGER_API_SECRET`: Your API secret for authentication.
   - `APP_NAME`: A unique identifier for your application.

   You can set these in a `.env` file for local development:

   ```
   CENTRAL_EVENT_LOGGER_API_ENDPOINT=https://api.example.com/log-events
   CENTRAL_EVENT_LOGGER_API_KEY=your_api_key_here
   CENTRAL_EVENT_LOGGER_API_SECRET=your_api_secret_here
   APP_NAME=YourAppName
   ```

3. **Use the Gem**: You can now use the `CentralEventLogger` to log events to the centralized logging service. Here's an example of how to use the `log_event` method:

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

By following these steps, you can integrate the `CentralEventLogger` gem into your Rails application and start logging events to the centralized logging service via the API endpoint.
