require './app'

require 'raven'

Raven.capture do
  run Sinatra::Application
end
