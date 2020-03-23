#!/usr/bin/env bash

########################
# include the magic
########################
. demo-magic.sh -d
#TYPE_SPEED=60
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

clear

TOPIC=$1
KAFKA_URL=

p "TopicName"
echo $TOPIC

# Creating 'schema-demo' topic
p ""
p "Create topic "
wait
pe "kafka-topics --bootstrap-server localhost:9092 --create --topic $TOPIC --partitions 1 --replication-factor 3"

# Listing topics
p ""
p "List Topics"
wait
pe "kafka-topics --bootstrap-server localhost:9092 --list"


# List schemas
p ""
p "List all Subjects and Schemas"
wait
pe "curl --silent --basic --user $SR_AUTH -X GET https:///subjects | jq ."
wait

# Compatibility
p ""
p "Listing global schema compatibility level"
wait
pe "curl --silent --basic --user $SR_AUTH -X GET https:///config | jq ."
wait

# Register manually
## Print the schema
p ""
p "Introducing a new schema"
wait
echo "{
  \"type\": \"record\",
  \"name\": \"Payment\",
  \"namespace\": \"io.confluent.examples.clients.basicavro\",
  \"fields\": [
    {
      \"name\": \"id\",
      \"type\": \"string\"
    },
    {
      \"name\": \"amount\",
      \"type\": \"double\"
    }
  ]
}"
wait

## Register it
p ""
p "Manual register the schema"
p "curl --user SR_AUTH -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '{\"schema\": \"{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}\"}' https:///subjects/$TOPIC-value/versions"
wait
curl --user $SR_AUTH -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}"}' https:///subjects/$TOPIC-value/versions | jq .
wait

# Listing schema versions on our topic
p ""
p "List the number of versions"
p "curl --silent --basic --user SR_AUTH -X GET https:///subjects/$TOPIC-value/versions | jq ."
wait
curl --silent --basic --user $SR_AUTH -X GET https:///subjects/$TOPIC-value/versions | jq .
wait
# Display latest schema
p ""
p "Display latest schema"
p "curl --silent --basic --user SR_AUTH -X GET https:///subjects/$TOPIC-value/versions/latest/schema | jq ."
wait
curl --silent --basic --user $SR_AUTH -X GET https:///subjects/$TOPIC-value/versions/latest/schema | jq .
wait
# Compatibility topic
p ""
p "Display the topic compatibility"
p "curl --silent --basic --user SR_AUTH -X GET -H "Content-Type: application/vnd.schemaregistry.v1+json" https:///config/$TOPIC-value?defaultToGlobal=true | jq ."
wait
curl --silent --basic --user $SR_AUTH -X GET -H "Content-Type: application/vnd.schemaregistry.v1+json" https:///config/$TOPIC-value?defaultToGlobal=true | jq .
wait
# Change Compatibility
p ""
p "Change the compatibility to NONE"
p "curl --silent --basic --user SR_AUTH -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"compatibility":"NONE"}' https:///config/$TOPIC-value | jq ."
wait
curl --silent --basic --user $SR_AUTH -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"compatibility":"NONE"}' https:///config/$TOPIC-value | jq .
wait

## Produce using current schema
p ""
p "Produce messages with the schema"
wait
pe "kafka-avro-console-producer \
    --broker-list localhost:9092 \
    --property schema.registry.url=https:// \
    --property schema.registry.basic.auth.user.info= \
    --property basic.auth.credentials.source=USER_INFO \
    --topic $TOPIC \
    --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"}]}'"
# kafka-avro-console-producer \
#     --broker-list localhost:9092 \
#     --property schema.registry.url=https:// \
#     --property schema.registry.basic.auth.user.info= \
#     --property basic.auth.credentials.source=USER_INFO \
#     --topic $TOPIC \
#     --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"}]}'
# {"id": "1","amount": 10}
# {"id": "2","amount": 10}
# {"id": "3","amount": 10}
# {"id": "5","amount": 10}
# {"id": "6","amount": 10}
# {"id": "4","amount": 10}
# {"id": "7","amount": 10}

wait
#
# # Register a schema via producing a message
# ## Print new schema
p ""
p "Introducing a new schema via producing a message"
wait
echo "{
  \"type\": \"record\",
  \"name\": \"Payment\",
  \"namespace\": \"io.confluent.examples.clients.basicavro\",
  \"fields\": [
    {
      \"name\": \"id\",
      \"type\": \"string\"
    },
    {
      \"name\": \"amount\",
      \"type\": \"double\"
    },
    {
      \"name\": \"newfield\",
      \"type\": \"string\"
    }
  ]
}"
wait
#

#
pe "kafka-avro-console-producer \
    --broker-list localhost:9092 \
    --producer.config .ccloud/config \
    --property schema.registry.url=https:// \
    --property schema.registry.basic.auth.user.info= \
    --property basic.auth.credentials.source=USER_INFO \
    --topic $TOPIC \
    --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"},{\"name\": \"newfield\", \"type\": \"string\"}]}'"

kafka-avro-console-producer \
    --broker-list localhost:9092 \
    --producer.config .ccloud/config \
    --property schema.registry.url=https:// \
    --property schema.registry.basic.auth.user.info= \
    --property basic.auth.credentials.source=USER_INFO \
    --topic $TOPIC \
    --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"},{"name": "newfield", "type": "string"}]}'
# {"id": "111","amount": 10,"newfield": "sample123"}
# {"id": "22","amount": 10,"newfield": {"string":"sample"}}
# {"id": "33","amount": 10,"newfield": {"string":"sample"}}
# {"id": "44","amount": 10,"newfield": {"string":"sample"}}
# {"id": "55","amount": 10,"newfield": {"string":"sample"}}
# {"id": "66","amount": 10,"newfield": {"string":"sample"}}
# {"id": "77","amount": 10,"newfield": {"string":"sample"}}
# {"id": "88","amount": 10,"newfield": {"string":"sample"}}

wait

p ""
p "Consume the messages"
wait
pe "kafka-avro-console-consumer \
    --bootstrap-server localhost:9092 \
    --consumer.config .ccloud/config \
    --property schema.registry.url=https:// \
    --property schema.registry.basic.auth.user.info= \
    --property basic.auth.credentials.source=USER_INFO \
    --topic $TOPIC \
    --from-beginning"

wait
p "Fin"

kafka-console-producer \
    --broker-list localhost:9092 \
    --producer.config .ccloud/config \
    --topic $TOPIC
#
# kafka-avro-console-consumer \
#     --bootstrap-server localhost:9092 \
#     --consumer.config .ccloud/config \
#     --property schema.registry.url=https:// \
#     --property schema.registry.basic.auth.user.info= \
#     --property basic.auth.credentials.source=USER_INFO \
#     --topic $TOPIC \
#     --from-beginning
#
kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --consumer.config .ccloud/config \
    --topic $TOPIC \
    --from-beginning
#
# # Useful links
# ## https://docs.confluent.io/current/schema-registry/index.html
# ## https://docs.confluent.io/current/schema-registry/avro.html

# # Delete
# curl -X DELETE -u $SR_AUTH https:///subjects/

# # Schema with backwards compatibility
# kafka-avro-console-producer \
#     --broker-list localhost:9092 \
#     --producer.config .ccloud/config \
#     --property schema.registry.url=https:// \
#     --property schema.registry.basic.auth.user.info= \
#     --property basic.auth.credentials.source=USER_INFO \
#     --topic $TOPIC \
#     --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"},{"name": "newfield", "type": ["null", "string"], "default": null}]}'
