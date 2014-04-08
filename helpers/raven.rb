if ENV['SENTRY_DSN']
  require 'raven'

  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.environments = %w[staging production]
  end
end

module Helpers
  def capture_exception(e, env)
    if ENV['SENTRY_DSN']
      evt = Raven::Event.capture_rack_exception(e, env)
      Raven.send(evt) if evt
    end
  end
end
