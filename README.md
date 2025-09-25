## Usage

1. **Add the Gem to Your Gemfile**: Include the gem in your application's Gemfile by referencing the GitHub repository, and then run `bundle install`.

   ```ruby
   gem 'central_event_logger', git: 'https://github.com/eshopguide/centralized-logging.git'
   ```

2. **Set Environment Variables**: Ensure the following environment variables are set in your environment:

   - `CENTRAL_EVENT_LOGGER_API_BASE_URL`: Base URL of the central reporting API (e.g. `https://api.example.com`).
   - `CENTRAL_EVENT_LOGGER_API_KEY`: Your API key for the central reporting API.
   - `CENTRAL_EVENT_LOGGER_API_SECRET`: Your API secret for the central reporting API.
   - `APP_NAME`: A unique identifier for your application.
   - Optional adapter settings:
     - `CENTRAL_EVENT_LOGGER_ADAPTERS`: Comma-separated list of adapters. Defaults to `central_api`. Example: `central_api,posthog`.
     - `POSTHOG_PROJECT_API_KEY`: Your PostHog project API key (required when enabling `posthog`).
     - `POSTHOG_API_HOST`: PostHog ingest host (defaults to `https://eu.posthog.com`).

   You can set these in a `.env` file for local development:

   ```
   CENTRAL_EVENT_LOGGER_API_BASE_URL=https://api.example.com
   CENTRAL_EVENT_LOGGER_API_KEY=your_api_key_here
   CENTRAL_EVENT_LOGGER_API_SECRET=your_api_secret_here
   APP_NAME=YourAppName
   # Optional: enable PostHog
   CENTRAL_EVENT_LOGGER_ADAPTERS=central_api,posthog
   POSTHOG_PROJECT_API_KEY=phc_xxx
   POSTHOG_API_HOST=https://eu.posthog.com
   ```

### Adapters

CentralEventLogger supports multiple delivery adapters. By default, events are sent to the central reporting API via the `central_api` adapter. You can opt-in to additional sinks (like PostHog) without changing your application code.

- **Default behavior**: `CENTRAL_EVENT_LOGGER_ADAPTERS` defaults to `central_api`.
- **Usability guard**: An event is only enqueued if at least one configured adapter is usable (e.g., central API has a base URL, or PostHog has a project API key).
- **Enable PostHog**: set `CENTRAL_EVENT_LOGGER_ADAPTERS=central_api,posthog` and provide `POSTHOG_PROJECT_API_KEY` (and optionally `POSTHOG_API_HOST`).

Internally, the PostHog adapter uses the official `posthog-ruby` client to `capture` events and `flush` them. See PostHog docs for details: [Ruby library](https://posthog.com/docs/libraries/ruby), [API overview](https://posthog.com/docs/api).

#### Per-call adapter selection

You can override the configured adapters per `log_event` call using the `adapters:` parameter. This is useful when a specific event should only be sent to a subset of sinks.

```ruby
CentralEventLogger.log_event(
  event_name: "order_processed",
  event_type: "business_event",
  customer_myshopify_domain: shop.shopify_domain,
  payload: { order_id: order.id },
  adapters: [:posthog] # sends only to PostHog for this call
)
```

Notes:
- The enqueue guard checks that at least one of the provided adapters is usable.
- If `adapters:` is omitted, the configured adapters (e.g., `central_api`) are used.

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
