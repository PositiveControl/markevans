require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Markevans
  class Application < Rails::Application
    # Use UUIDs as primary keys by default
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # Autoload app/lib for registries and game config
    config.autoload_paths << Rails.root.join("app/lib")

    # ViewComponent: generate a sidecar directory so a component's class,
    # template, and any component-scoped Stimulus controller sit together.
    # Template engine follows config.generators.template_engine, which
    # slim-rails sets to :slim.
    config.view_component.generate.sidecar = true

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
