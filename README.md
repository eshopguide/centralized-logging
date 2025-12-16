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
     - `CENTRAL_EVENT_LOGGER_ADAPTERS`: Comma-separated list of adapters. Defaults to `central_api`. Example: `central_api,posthog,klaviyo`.
     - `POSTHOG_PROJECT_API_KEY`: Your PostHog project API key (required when enabling `posthog`).
     - `POSTHOG_API_HOST`: PostHog ingest host (defaults to `https://eu.posthog.com`).
     - `KLAVIYO_API_KEY`: Your Klaviyo Private API Key (required when enabling `klaviyo`).

   You can set these in a `.env` file for local development:

   ```
   CENTRAL_EVENT_LOGGER_API_BASE_URL=https://api.example.com
   CENTRAL_EVENT_LOGGER_API_KEY=your_api_key_here
   CENTRAL_EVENT_LOGGER_API_SECRET=your_api_secret_here
   APP_NAME=YourAppName
   # Optional: enable PostHog and Klaviyo
   CENTRAL_EVENT_LOGGER_ADAPTERS=central_api,posthog,klaviyo
   POSTHOG_PROJECT_API_KEY=phc_xxx
   POSTHOG_API_HOST=https://eu.posthog.com
   KLAVIYO_API_KEY=pk_xxx
   ```

### Adapters

CentralEventLogger supports multiple delivery adapters. By default, events are sent to the central reporting API via the `central_api` adapter. You can opt-in to additional sinks (like PostHog or Klaviyo) without changing your application code.

- **Default behavior**: `CENTRAL_EVENT_LOGGER_ADAPTERS` defaults to `central_api`.
- **Usability guard**: An event is only enqueued if at least one configured adapter is usable (e.g., central API has a base URL, PostHog has a project API key, or Klaviyo has an API key).

#### Available Adapters

**Central API** (`central_api`)
- The default adapter that sends events to your centralized logging API
- Requires: `CENTRAL_EVENT_LOGGER_API_BASE_URL`, `CENTRAL_EVENT_LOGGER_API_KEY`, `CENTRAL_EVENT_LOGGER_API_SECRET`

**PostHog** (`posthog`)
- Sends events to PostHog for product analytics
- Uses the official `posthog-ruby` client to `capture` events and `flush` them
- Requires: `POSTHOG_PROJECT_API_KEY`
- Optional: `POSTHOG_API_HOST` (defaults to `https://eu.posthog.com`)
- Docs: [Ruby library](https://posthog.com/docs/libraries/ruby), [API overview](https://posthog.com/docs/api)

**Klaviyo** (`klaviyo`)
- Sends events to Klaviyo for email marketing and customer engagement
- Uses the official `klaviyo-api-sdk` gem to create events and update profiles
- Requires: `KLAVIYO_API_KEY` (Private API Key from https://www.klaviyo.com/settings/account/api-keys)
- **Important**: Customer email is required in `customer_info[:email]` for Klaviyo events
- Profile data is automatically created/updated from `customer_info` fields
- Docs: [Klaviyo Ruby SDK](https://github.com/klaviyo/klaviyo-api-ruby)

To enable multiple adapters:
```bash
CENTRAL_EVENT_LOGGER_ADAPTERS=central_api,posthog,klaviyo
```

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

### Event Whitelisting

You can configure whitelists for each adapter to only process specific events. This is useful when you want to send all events to one adapter (e.g., `central_api`) but only specific events to another (e.g., `klaviyo`).

In your configuration initializer:

```ruby
# config/initializers/central_event_logger.rb
CentralEventLogger.configure do |config|
  # ... other config ...

  # Configure event whitelists per adapter
  config.adapter_event_whitelists = {
    # Only send these specific events to Klaviyo
    klaviyo: ["app_installed", "app_uninstalled", "conversion", "connection_lost"],
    
    # Send only 'page_view' to PostHog
    posthog: ["page_view"]
  }
end
```

If an adapter is not present in the `adapter_event_whitelists` hash (or if the list is empty/nil), it will process **all** events by default.

### Adding Custom Adapters

The gem uses an open Adapter Factory pattern that makes it easy to add new event destinations without modifying the gem internals. To create a custom adapter:

1. **Create your adapter class** inheriting from `CentralEventLogger::Adapters::BaseAdapter` in `lib/central_event_logger/adapters/my_custom_adapter.rb` (filename must match the adapter name + `_adapter.rb`):

```ruby
# lib/central_event_logger/adapters/my_custom_adapter.rb
module CentralEventLogger
  module Adapters
    class MyCustomAdapter < BaseAdapter
      def initialize(api_key)
        @api_key = api_key
      end

      # Required: Check if adapter is configured
      # @param config [CentralEventLogger::Configuration]
      def self.available?(config)
        !config.my_custom_api_key.nil?
      end

      # Required: Create instance from configuration
      # @param config [CentralEventLogger::Configuration]
      def self.from_config(config)
        new(config.my_custom_api_key)
      end

      # Required: Send event to destination
      # @param event_data [Hash]
      def capture_event(event_data)
        # Transform event_data and send to your service
        # Return true on success, false on failure
      end
    end
  end
end

# Required: Register the adapter
CentralEventLogger::Adapters::AdapterRegistry.register(:my_custom, CentralEventLogger::Adapters::MyCustomAdapter)
```

2. **Add configuration** in `lib/central_event_logger/configuration.rb`:

```ruby
attr_accessor :my_custom_api_key

def initialize
  # ... existing code ...
  @my_custom_api_key = ENV["MY_CUSTOM_API_KEY"]
end
```

3. **Use your adapter**:

```bash
CENTRAL_EVENT_LOGGER_ADAPTERS=central_api,my_custom
MY_CUSTOM_API_KEY=your_key_here
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
