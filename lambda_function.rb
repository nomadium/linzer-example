# frozen_string_literal: true

require "srack"

RACK_APP_CONFIG = "#{__dir__}/config.ru"

# Global object that responds to the call method.
# Stay outside of the handler to take advantage of container reuse.
$app ||= Rack::Builder.parse_file(RACK_APP_CONFIG)

def lambda_handler(event:, context:)
  SRack::AWSLambdaHandler
    .new($app)
    .handle(event:, context:)
end
