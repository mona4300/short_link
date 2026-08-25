# Non-Rails RSpec settings. Loaded by rails_helper.rb for every spec run.
RSpec.configure do |config|
  # Use RSpec's built-in expectation library (expect(...).to ...).
  config.expect_with :rspec do |expectations|
    # Include chained matcher text in custom matcher descriptions and failure
    # messages, e.g. be_bigger_than(2).and_smaller_than(4) describes the full chain.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Use RSpec's built-in mocking library (double, allow, expect(...).to receive).
  config.mock_with :rspec do |mocks|
    # Fail when stubbing/mocking a method that does not exist on the real object.
    # Catches typos and API drift early (e.g. allow(user).to receive(:nmae)).
    mocks.verify_partial_doubles = true
  end

  # When metadata is set on a shared context, apply it to the groups/examples
  # that include that context (instead of only to the shared context itself).
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # If any example or group is tagged with :focus, run only those.
  # Usage: it "works", :focus do ... end  or  fit / fdescribe / fcontext.
  config.filter_run_when_matching :focus

  # Persist last run status (passed/failed) here so --only-failures and
  # --next-failure can re-run the failing examples from the previous run.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Do not mix RSpec DSL into every Object (no bare `should` / `stub` globally).
  # Prefer expect syntax and explicit includes; keeps the global namespace clean.
  config.disable_monkey_patching!

  # Shuffle example order each run to surface order-dependent (flaky) specs.
  config.order = :random

  # Seed Ruby's RNG with RSpec's seed so randomized order is reproducible via
  # --seed when debugging a failure that only appears in a certain order.
  Kernel.srand config.seed
end
