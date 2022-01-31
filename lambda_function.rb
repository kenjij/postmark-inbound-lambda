require 'json'
require_relative './lib/logger'
require_relative './lib/handlers'

PINS::Handler.import

def lambda_handler(event:, context:)
  abort unless preflightcheck
  c = PINS::Handler.run(event)
  PINS.logger.info("Ran #{c} handlers.")
  {statusCode: 200}
end

def preflightcheck
  l = ENV['PINS_LOG_LEVEL']
  if String === l && ['DEBUG', 'INFO', 'WARN', 'ERROR'].include?(l.upcase)
    PINS.logger.level = eval("Logger::#{l.upcase}")
  end
  true
end
