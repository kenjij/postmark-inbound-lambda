# postmark-inbound-lambda

Postmark inbound webhook Lamda function in Ruby

## API Gateway Authorizer: Seki

Use [seki-lambda](https://github.com/propelfuels/seki-lambda) to authorize access via API Gateway. Authorization entries should always include `context` like below.

```json
{
  "context": {
    "server": "<server_name>"
  }
}
```

The `server` obtained via this authorizer determines which handlers are triggered.

## Handlers

Create any number of handlers for a given `server_name` to respond to the incoming query.

```ruby
PINS::Handler.add('<server_name>', 'Handler_name') do |pin, myself|
  next unless pin['OriginalRecipient'] == 'agents@example.net'
	myself.stop
  PINS.logger.debug "Message with subject: #{pin['Subject']}"
end
```
