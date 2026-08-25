# Rails-aware RSpec setup. Specs should require this file (not spec_helper alone).
require "spec_helper"

# Default the process to the test environment unless already set (e.g. by CI).
ENV["RAILS_ENV"] ||= "test"

# Boot the Rails app so models, routes, and config are available in specs.
require_relative "../config/environment"

# Refuse to run if somehow loaded under production (avoids wiping prod data).
abort("The Rails environment is running in production mode!") if Rails.env.production?

# RSpec extensions for Rails (controller/request/routing/model helpers, matchers).
require "rspec/rails"

# Autoload every Ruby file under spec/support (FactoryBot config, shared helpers).
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

begin
  # Ensure the test DB schema matches migrations before any example runs.
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  # Stop immediately with a clear message if migrations are pending.
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Where YAML fixtures live if you use fixture(:users) instead of FactoryBot.
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]

  # Wrap each example in a DB transaction and roll it back afterward so test
  # data does not leak between examples. Preferred default for ActiveRecord apps.
  config.use_transactional_fixtures = true

  # Infer spec type from path: spec/controllers → :controller, spec/routing →
  # :routing, etc., so you do not need type: :controller on every describe.
  config.infer_spec_type_from_file_location!

  # Omit Rails framework frames from failure backtraces to highlight app code.
  config.filter_rails_from_backtrace!
end
