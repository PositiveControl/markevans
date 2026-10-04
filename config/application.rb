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

    # ViewComponent: generate a sidecar directory so a component's class,
    # template, and any component-scoped Stimulus controller sit together.
    # Template engine follows config.generators.template_engine, which
    # slim-rails sets to :slim.
    config.view_component.generate.sidecar = true

    # lib/qa_walkthrough.rb requires capybara, a development/test gem.
    # bin/qa-walkthrough autoloads it; eager-loading it would make production
    # boot raise LoadError wherever the bundle leaves out the test group.
    Rails.autoloaders.main.do_not_eager_load(Rails.root.join("lib/qa_walkthrough.rb"))

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

    # /work/<key> with no such project is a 404, as a missing record is: the
    # lookup raises and Rails answers, with no rescue in a controller
    # (docs/rules/exception-boundary.md).
    config.action_dispatch.rescue_responses["Portfolio::NotFound"] = :not_found
  end
end
