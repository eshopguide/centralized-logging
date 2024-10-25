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

3. **Configure Shop Attribute Mapping** (Optional): If your application uses different attribute names for shop-related data, you can configure the mappings in an initializer:

   ```ruby
   # config/initializers/central_event_logger.rb
   CentralEventLogger.configure do |config|
     # Configure custom shop attribute mappings
     # These are the default values:
     config.shop_attribute_mappings = {
       domain: :shopify_domain,    # Method to get shop's Shopify domain
       name: :name,                # Method to get shop's name
       email: :email,              # Method to get shop's email
       owner: :shop_owner          # Method to get shop owner's name
     }
   end
   ```

   This configuration tells the gem which methods to call on your shop model to retrieve various shop attributes. The defaults are:
   - `:domain` - maps to `:shopify_domain` method
   - `:name` - maps to `:name` method
   - `:email` - maps to `:email` method
   - `:owner` - maps to `:shop_owner` method

4. **Use the Gem**: You can now use the `CentralEventLogger` to log events to the centralized logging service. Here's an example of how to use the `log_event` method:

   ```ruby
   CentralEventLogger.log_event(
     event_name: attribute,
     event_type: CentralEventLogger::EventTypes::SETTINGS_CHANGE,
     customer_myshopify_domain: shop.shopify_domain,
     customer_info: {
       name: shop.name,
       email: shop.email,
       owner: shop.shop_owner
     },
     event_value: changes.last,
     payload: { from: changes.first, to: changes.last },
     app_name: CentralEventLogger.configuration.app_name
   )
   ```

   This example shows logging a settings change event. The parameters are:
   - `event_name`: The name of the event (in this case, the attribute that changed)
   - `event_type`: The type of event (using a predefined constant from `CentralEventLogger::EventTypes`)
   - `customer_myshopify_domain`: The Shopify domain of the customer
   - `customer_info`: A hash containing shop details (name, email, and owner)
   - `event_value`: The new value after the change
   - `payload`: Additional information about the event (in this case, the old and new values)
   - `app_name`: The name of your application (retrieved from the configuration)

   Make sure to adjust the parameters according to the event you're logging and the data available in your context.

5. **Automatic Change Tracking**: To automatically track model changes, include the `Trackable` module in your model:

   ```ruby
   class YourModel < ApplicationRecord
     include CentralEventLogger::Trackable
   end
   ```

   This will automatically log any changes to your model's attributes (except `id`, `created_at`, and `updated_at`).

By following these steps, you can integrate the `CentralEventLogger` gem into your Rails application and start logging events to the centralized logging service via the API endpoint.
