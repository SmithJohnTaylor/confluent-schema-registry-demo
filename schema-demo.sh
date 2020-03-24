#!/usr/bin/env bash

########################
# include the magic
########################
. demo-magic.sh -d

#TYPE_SPEED=60
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

clear

########################
# end demo magic config
########################

TOPIC=$1
KAFKA_URL=localhost:9092
SR_URL=http://localhost:8081

p "TopicName"
echo $TOPIC

# Creating 'schema-demo' topic
p ""
p "Create topic "
wait
pe "kafka-topics --bootstrap-server $KAFKA_URL --create --topic $TOPIC --partitions 1 --replication-factor 1"

# Listing topics
p ""
p "List Topics"
wait
pe "kafka-topics --bootstrap-server $KAFKA_URL --list"


# List schemas
p ""
p "List all Subjects and Schemas"
wait
pe "curl --silent --basic -X GET $SR_URL/subjects | jq ."
wait

# Compatibility
p ""
p "Listing global schema compatibility level"
wait
pe "curl --silent --basic -X GET $SR_URL/config | jq ."
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
p "curl -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '{\"schema\": \"{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}\"}' $SR_URL/subjects/$TOPIC-value/versions"
wait
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}"}' $SR_URL/subjects/$TOPIC-value/versions | jq .
wait

# Listing schema versions on our topic
p ""
p "List the number of versions"
p "curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions | jq ."
wait
curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions | jq .
wait
# Display latest schema
p ""
p "Display latest schema"
p "curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions/latest/schema | jq ."
wait
curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions/latest/schema | jq .
wait
# Compatibility topic
p ""
p "Display the topic compatibility"
p "curl --silent --basic -X GET -H \"Content-Type: application/vnd.schemaregistry.v1+json\" \"$SR_URL/config/$TOPIC-value?defaultToGlobal=true\" | jq ."
wait
curl --silent --basic -X GET -H "Content-Type: application/vnd.schemaregistry.v1+json" "$SR_URL/config/$TOPIC-value?defaultToGlobal=true" | jq .
wait
# Change Compatibility
p ""
p "Change the compatibility to NONE"
p "curl --silent --basic -X PUT -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '{\"compatibility\":\"NONE\"}' $SR_URL/config/$TOPIC-value | jq ."
wait
curl --silent --basic -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"compatibility":"NONE"}' $SR_URL/config/$TOPIC-value | jq .
wait

## Produce using current schema
p ""
p "Produce messages with the schema"
wait
pe "kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"}]}'"
# kafka-avro-console-producer \
#     --broker-list $KAFKA_URL \
#     --property schema.registry.url=$SR_URL \
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
    --broker-list $KAFKA_URL \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"},{\"name\": \"newfield\", \"type\": \"string\"}]}'"

# kafka-avro-console-producer \
#     --broker-list $KAFKA_URL \
#     --producer.config .ccloud/config \
#     --property schema.registry.url=$SR_URL \
#     --property schema.registry.basic.auth.user.info= \
#     --property basic.auth.credentials.source=USER_INFO \
#     --topic $TOPIC \
#     --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"},{"name": "newfield", "type": "string"}]}'
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
    --bootstrap-server $KAFKA_URL \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --from-beginning"

wait
p "Fin"

# kafka-console-producer \
#     --broker-list $KAFKA_URL \
#     --producer.config .ccloud/config \
#     --topic $TOPIC
#
# kafka-avro-console-consumer \
#     --bootstrap-server $KAFKA_URL \
#     --consumer.config .ccloud/config \
#     --property schema.registry.url=$SR_URL \
#     --property schema.registry.basic.auth.user.info= \
#     --property basic.auth.credentials.source=USER_INFO \
#     --topic $TOPIC \
#     --from-beginning
#
# kafka-console-consumer \
#     --bootstrap-server $KAFKA_URL \
#     --consumer.config .ccloud/config \
#     --topic $TOPIC \
#     --from-beginning
#
# # Useful links
# ## https://docs.confluent.io/current/schema-registry/index.html
# ## https://docs.confluent.io/current/schema-registry/avro.html

# # Delete
# curl -X DELETE -u $SR_AUTH $SR_URL/subjects/

# # Schema with backwards compatibility
# kafka-avro-console-producer \
#     --broker-list $KAFKA_URL \
#     --producer.config .ccloud/config \
#     --property schema.registry.url=$SR_URL \
#     --property schema.registry.basic.auth.user.info= \
#     --property basic.auth.credentials.source=USER_INFO \
#     --topic $TOPIC \
#     --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"},{"name": "newfield", "type": ["null", "string"], "default": null}]}'

#  --user $SR_AUTH