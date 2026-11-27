# Collects the errors reported to Rails.error while the block runs:
#
#   expect(reported_errors { do_work }).to include(an_instance_of(SomeError))
module ReportedErrors
  def reported_errors
    reports = []
    subscriber = Object.new
    subscriber.define_singleton_method(:report) { |error, **| reports << error }

    Rails.error.subscribe(subscriber)
    yield
    reports
  ensure
    Rails.error.unsubscribe(subscriber)
  end
end

RSpec.configure do |config|
  config.include ReportedErrors
end
