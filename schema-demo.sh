#!/usr/bin/env bash

TOPIC=$1
KAFKA_URL=localhost:9092
SR_URL=http://localhost:8081

echo "TopicName"
echo $TOPIC

#------------------------------#
# Creating 'schema-demo' topic #
#------------------------------#
echo
echo "Create topic "
kafka-topics --bootstrap-server $KAFKA_URL --create --topic $TOPIC --partitions 1 --replication-factor 1
read -p "Press enter to continue"
################################

#------------------------------#
# Listing topics
#------------------------------#
echo
echo "Listing Topics"
echo "kafka-topics --bootstrap-server $KAFKA_URL --list"
kafka-topics --bootstrap-server $KAFKA_URL --list | awk '!/_/{print }'
read -p "Press enter to continue"

#------------------------------#
# List schemas
#------------------------------#
echo
echo "List all Subjects and Schemas"
echo "curl --silent --basic -X GET $SR_URL/subjects | jq ."
curl --silent --basic -X GET $SR_URL/subjects | jq .
read -p "Press enter to continue"

#------------------------------#
# Compatibility
#------------------------------#
echo
echo "Listing global schema compatibility level"
echo "curl --silent --basic -X GET $SR_URL/config | jq ."
curl --silent --basic -X GET $SR_URL/config | jq .
read -p "Press enter to continue"

#------------------------------#
# Register manually
#------------------------------#
## Print the schema
echo
echo "Introducing a new schema"
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
read -p "Press enter to continue"

## Register it
echo
echo "Manual register the schema"
echo "curl -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '{\"schema\": \"{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}\"}' $SR_URL/subjects/$TOPIC-value/versions"
curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}"}' $SR_URL/subjects/$TOPIC-value/versions | jq .
read -p "Press enter to continue"

#------------------------------#
# Listing schema versions on our topic
#------------------------------#
echo
echo "List the number of versions"
echo "curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions | jq ."
curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions | jq .
read -p "Press enter to continue"

#------------------------------#
# Display latest schema
#------------------------------#
echo
echo "Display latest schema"
echo "curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions/latest/schema | jq ."
curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions/latest/schema | jq .
read -p "Press enter to continue"

#------------------------------#
# Compatibility topic
#------------------------------#
echo
echo "Display the topic compatibility"
echo "curl --silent --basic -X GET -H \"Content-Type: application/vnd.schemaregistry.v1+json\" \"$SR_URL/config/$TOPIC-value?defaultToGlobal=true\" | jq ."
curl --silent --basic -X GET -H "Content-Type: application/vnd.schemaregistry.v1+json" "$SR_URL/config/$TOPIC-value?defaultToGlobal=true" | jq .
read -p "Press enter to continue"

#------------------------------#
## Produce using current schema
#------------------------------#
echo
echo "Produce messages with the schema -> {\"id\": \"1\",\"amount\": 10}"
kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"}]}' << EOF
{"id": "1","amount": 10}
{"id": "2","amount": 10}
{"id": "3","amount": 10}
{"id": "5","amount": 10}
{"id": "6","amount": 10}
{"id": "4","amount": 10}
{"id": "7","amount": 10}
EOF
read -p "Press enter to continue"

#------------------------------#
## Produce using incompatible schema
#------------------------------#
echo
echo "Attempt to register an incompatible schema"
echo
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
    }.
    {
      \"name\": \"newfield\",
      \"type\": \"string\"
    }
  ]
}"
read -p "Press enter to continue"
echo "Produce messages with the incompatible schema -> {\"id\": \"111\",\"amount\": 10,\"newfield\": \"sample123\"}"
echo "kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"},{\"name\": \"newfield\", \"type\": \"string\"}]}'"
kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"},{"name": "newfield", "type": "string"}]}' << EOF
{"id": "111","amount": 10,"newfield": "sample123"}
EOF
read -p "Press enter to continue"

#------------------------------#
# Change Compatibility
echo
echo "Change the compatibility to NONE"
echo "curl --silent --basic -X PUT -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '{\"compatibility\":\"NONE\"}' $SR_URL/config/$TOPIC-value | jq ."
curl --silent --basic -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"compatibility":"NONE"}' $SR_URL/config/$TOPIC-value | jq .
read -p "Press enter to continue"

echo "Try again -> {\"id\": \"111\",\"amount\": 10,\"newfield\": \"sample123\"}"
echo "kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"},{\"name\": \"newfield\", \"type\": \"string\"}]}'"
kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"},{"name": "newfield", "type": "string"}]}' << EOF
{"id": "111","amount": 10,"newfield": "sample123"}
EOF


#------------------------------#
# Listing schema versions on our topic
#------------------------------#
echo
echo "List the number of versions"
echo "curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions | jq ."
curl --silent --basic -X GET $SR_URL/subjects/$TOPIC-value/versions | jq .
read -p "Press enter to continue"

echo
echo "Consume the messages"
kafka-avro-console-consumer \
    --bootstrap-server $KAFKA_URL \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --from-beginning

read -p "Press enter to continue"
echo "Fin"

# echo
# echo "Register the same schema, but now backwards compatible -> {\"id\": \"111\",\"amount\": 10,\"newfield\": \"sample123\"}"
# # Schema with backwards compatibility
# echo "kafka-avro-console-producer \
#     --broker-list $KAFKA_URL \
#     --property schema.registry.url=$SR_URL \
#     --topic $TOPIC \
#     --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"},{\"name\": \"newfield\", \"type\": [\"null\", \"string\"], \"default\": null}]}'"
# kafka-avro-console-producer \
#     --broker-list $KAFKA_URL \
#     --property schema.registry.url=$SR_URL \
#     --topic $TOPIC \
#     --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"},{"name": "newfield", "type": ["null", "string"], "default": null}]}' << EOF
# {"id": "111","amount": 10,"newfield": "sample123"}
# {"id": "222","amount": 10}
# EOF

# # TODO:

# # Change schema to none compatibilty
# # Show screenshots of C3
# # Consume

# # wait

# # wait

# # #
# # # # Register a schema via producing a message
# # # ## Print new schema
# # echo
# # p "Introducing a new schema via producing a message"
# # wait
# # echo "{
# #   \"type\": \"record\",
# #   \"name\": \"Payment\",
# #   \"namespace\": \"io.confluent.examples.clients.basicavro\",
# #   \"fields\": [
# #     {
# #       \"name\": \"id\",
# #       \"type\": \"string\"
# #     },
# #     {
# #       \"name\": \"amount\",
# #       \"type\": \"double\"
# #     },
# #     {
# #       \"name\": \"newfield\",
# #       \"type\": \"string\"
# #     }
# #   ]
# # }"
# # wait

# # pe "kafka-avro-console-producer \
# #     --broker-list $KAFKA_URL \
# #     --property schema.registry.url=$SR_URL \
# #     --topic $TOPIC \
# #     --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"},{\"name\": \"newfield\", \"type\": \"string\"}]}' << EOF
# # {\"id\": \"11\",\"amount\": 10,\"newfield\": \"sample123\"}
# # {\"id\": \"22\",\"amount\": 10,\"newfield\": \"sample123\"}
# # {\"id\": \"33\",\"amount\": 10,\"newfield\": \"sample123\"}
# # {\"id\": \"44\",\"amount\": 10,\"newfield\": \"sample123\"}
# # {\"id\": \"55\",\"amount\": 10,\"newfield\": \"sample123\"}
# # {\"id\": \"66\",\"amount\": 10,\"newfield\": \"sample123\"}
# # {\"id\": \"77\",\"amount\": 10,\"newfield\": \"sample123\"}
# # EOF"
# # wait
