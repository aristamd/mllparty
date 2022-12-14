# MLLParty 🎊

## Description

Small service that converts HTTP requests to MLLP messages (for sending HL7).

## Endpoint Reference

### `POST /api/mllp_messages`

#### Description

Validates and sends an HL7 message via MLLP


#### Parameters

| Param | Required | Description |
| ----- | -------- | ----------- |
| endpoint | **Yes** | The `<ip>:<port>` endpoint that you're sending a message to. Ex. `"10.120.0.4:2575"`. <br>**NOTE:** You can also put `"log"` for the `endpoint` param value and it will just log your HL7 message rather than send it (useful for dev/debugging) |
| message | **Yes** | The HL7 message you want to send. |


#### Example Request

```bash
# NB: The leading colon in the -u flag is required because it's basic auth with a blank username
curl -X POST http://localhost:4000/api/mllp_messages \
    -u ":sekret" \
    -H "Content-Type: application/json" \
    -d @- << 'EOF'
{
  "endpoint": "log",
  "message": "MSH|^~\\&|MegaReg|XYZHospC|SuperOE|XYZImgCtr|20060529090131-0500||ADT^A01^ADT_A01|01052901|P|2.5
EVN||200605290901||||
PID|||56782445^^^UAReg^PI||KLEINSAMPLE^BARRY^Q^JR||19620910|M||2028-9^^HL70005^RA99113^^XYZ|260 GOODWIN CREST DRIVE^^BIRMINGHAM^AL^35209^^M~NICKELL’S PICKLES^10000 W 100TH AVE^BIRMINGHAM^AL^35200^^O|||||||0105I30001^^^99DEF^AN
PV1||I|W^389^1^UABH^^^^3||||12345^MORGAN^REX^J^^^MD^0010^UAMC^L||67890^GRAINGER^LUCY^X^^^MD^0010^UAMC^L|MED|||||A0||13579^POTTER^SHERMAN^T^^^MD^0010^UAMC^L|||||||||||||||||||||||||||200605290900
OBX|1|NM|^Body Height||1.80|m^Meter^ISO+|||||F
OBX|2|NM|^Body Weight||79|kg^Kilogram^ISO+|||||F
AL1|1||^ASPIRIN
DG1|1||786.50^CHEST PAIN, UNSPECIFIED^I9|||A"
}
EOF
```


## Getting Started

### Running for development

There's a `docker-compose.yml` file containing a couple of services that together represent a "listening" or "receiving" MLLP endpoint. When sending messages to them, you won't receive an ACK, but you should see that your message was relayed/sent.

To start the MLLParty service, make sure you have elixir installed and then simply:

```
mix deps.get
mix phx.server
```

### Building / Running Docker Image

This service is provided as a Docker image. To build and run the container:

```bash
docker build . -t mllparty
docker run --rm --env API_KEY="sekret" --env SECRET_KEY_BASE="$(mix phx.gen.secret)" -p 4000:4000 mllparty
```


### Mix Task

For testing, you can send an HL7 message over MLLP by invoking the mix task:

```bash
# Start mllp-catcher and http-debugger services
docker compose up -d

# Install dependencies
mix deps.get

# Send a message from command line
mix send_mllp mllp://0.0.0.0:2595 "<your HL7 message, or leave blank to send test message>"

# You should now see the message in the logs of the mllp-catcher and http-debugger... You'll see an invalid_ack_message output in the console because our test endpoint isn't returning an ACK like a real system will.
```
