#!/usr/bin/env bash
GREEN="\033[0;32m"
NC="\033[0m"
clear
#------------------------------#
# Confluent Kafka environment details
#------------------------------#
PATH_TO_CCONFIG=$2
if [ -z "$PATH_TO_CCONFIG" ]
then
  echo "Path to cconfig file not specified. Defaulting to: ./cconfig"
  PATH_TO_CCONFIG="./cconfig"
fi

KAFKA_URL=$(cat $PATH_TO_CCONFIG | grep bootstrap.servers | awk '{split($0,a,"="); print a[2]}')
SR_URL=$(cat $PATH_TO_CCONFIG | grep schema.registry.url | awk '{split($0,a,"="); print a[2]}')
SR_AUTH="$(cat $PATH_TO_CCONFIG | grep schema.registry.basic.auth.user.info | awk '{split($0,a,"="); print a[2]}')"

if [ -z "$KAFKA_URL" ] || [ -z "$SR_URL" ] || [ -z "$SR_AUTH" ]
then
  echo "Kafka environment variables not set. Verify cconfig path."
  exit 1
fi 
#------------------------------#

TOPIC=$1
if [ -z "$TOPIC" ] 
then
  echo "Topic not specified. Defaulting topic to: schema-demo-topic"
  TOPIC="schema-demo-topic"
fi

echo
echo -e "${GREEN}TopicName${NC}"
echo $TOPIC

#------------------------------#
# Creating 'schema-demo' topic #
#------------------------------#
echo
echo -e "${GREEN}Creating topic${NC}"
echo "kafka-topics --bootstrap-server $KAFKA_URL --command-config $PATH_TO_CCONFIG --create --topic $TOPIC --partitions 1 --replication-factor 3"
kafka-topics --bootstrap-server $KAFKA_URL --command-config $PATH_TO_CCONFIG --create --topic $TOPIC --partitions 1 --replication-factor 3
read -p "Press enter to continue"
################################

#------------------------------#
# Listing topics
#------------------------------#
echo
echo -e "${GREEN}Listing Topics${NC}"
echo "kafka-topics --bootstrap-server $KAFKA_URL --command-config $PATH_TO_CCONFIG --list"
kafka-topics --bootstrap-server $KAFKA_URL --command-config $PATH_TO_CCONFIG --list | awk '!/_/{print }'
read -p "Press enter to continue"

#------------------------------#
# List schemas
#------------------------------#
echo
echo -e "${GREEN}Listing all Subjects and Schemas${NC}"
echo "curl --silent --basic --user $SR_AUTH -X GET $SR_URL/subjects | jq ."
curl --silent --basic --user $SR_AUTH -X GET $SR_URL/subjects | jq .
read -p "Press enter to continue"

#------------------------------#
# Compatibility
#------------------------------#
echo
echo -e "${GREEN}Listing global schema compatibility level${NC}"
echo "curl --silent --basic --user $SR_AUTH -X GET $SR_URL/config | jq ."
curl --silent --basic --user $SR_AUTH -X GET $SR_URL/config | jq .
read -p "Press enter to continue"

#------------------------------#
# Register manually
#------------------------------#
## Print the schema
echo
echo -e "${GREEN}Introducing a new schema${NC}"
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
echo -e "${GREEN}Manually register the schema${NC}"
echo "curl --user $SR_AUTH -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '{\"schema\": \"{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}\"}' $SR_URL/subjects/$TOPIC-value/versions"

curl --user $SR_AUTH -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\":\"record\",\"name\":\"Payment\",\"namespace\":\"io.confluent.examples.clients.basicavro\",\"fields\":[{\"name\":\"id\",\"type\":\"string\"},{\"name\":\"amount\",\"type\":\"double\"}]}"}' $SR_URL/subjects/$TOPIC-value/versions | jq .

read -p "Press enter to continue"

#------------------------------#
# Listing schema versions on our topic
#------------------------------#
echo
echo -e "${GREEN}List the number of versions${NC}"
echo "curl --silent --basic --user $SR_AUTH -X GET $SR_URL/subjects/$TOPIC-value/versions | jq ."
curl --silent --basic --user $SR_AUTH -X GET $SR_URL/subjects/$TOPIC-value/versions | jq .
read -p "Press enter to continue"

#------------------------------#
# Display latest schema
#------------------------------#
echo
echo -e "${GREEN}Display latest schema${NC}"
echo "curl --silent --basic --user $SR_AUTH -X GET $SR_URL/subjects/$TOPIC-value/versions/latest/schema | jq ."
curl --silent --basic --user $SR_AUTH -X GET $SR_URL/subjects/$TOPIC-value/versions/latest/schema | jq .
read -p "Press enter to continue"

#------------------------------#
# Compatibility topic
#------------------------------#
echo
echo -e "${GREEN}Display the topic compatibility${NC}"
echo "curl --silent --basic --user $SR_AUTH -X GET -H \"Content-Type: application/vnd.schemaregistry.v1+json\" \"$SR_URL/config/$TOPIC-value?defaultToGlobal=true\" | jq ."
curl --silent --basic --user $SR_AUTH -X GET -H "Content-Type: application/vnd.schemaregistry.v1+json" "$SR_URL/config/$TOPIC-value?defaultToGlobal=true" | jq .
read -p "Press enter to continue"

#------------------------------#
## Produce using current schema
#------------------------------#
echo
echo -e "${GREEN}Produce messages with the schema -> {\"id\": \"1\",\"amount\": 10}${NC}"
echo "kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --producer.config $PATH_TO_CCONFIG
    --property schema.registry.basic.auth.user.info=$SR_AUTH \
    --property basic.auth.credentials.source=USER_INFO \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"}]}'"
kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --producer.config $PATH_TO_CCONFIG \
    --property schema.registry.basic.auth.user.info=$SR_AUTH \
    --property basic.auth.credentials.source=USER_INFO \
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
echo "{\"id\": \"1\",\"amount\": 10}"
read -p "Press enter to continue"

#------------------------------#
## Produce using incompatible schema
#------------------------------#
echo
echo -e "${GREEN}Attempt to register an incompatible schema${NC}"
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
echo -e "${GREEN}Produce messages with the incompatible schema -> {\"id\": \"111\",\"amount\": 10,\"newfield\": \"sample123\"}${NC}"
echo "kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --producer.config $PATH_TO_CCONFIG \
    --property schema.registry.basic.auth.user.info=$SR_AUTH \
    --property basic.auth.credentials.source=USER_INFO \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"},{\"name\": \"newfield\", \"type\": \"string\"}]}'"
kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --producer.config $PATH_TO_CCONFIG \
    --property schema.registry.basic.auth.user.info=$SR_AUTH \
    --property basic.auth.credentials.source=USER_INFO \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"},{"name": "newfield", "type": "string"}]}' << EOF
{"id": "111","amount": 10,"newfield": "sample123"}
EOF
read -p "Press enter to continue"

#------------------------------#
# Change Compatibility
#------------------------------#
echo
echo -e "${GREEN}Change the compatibility to NONE${NC}"
echo "curl --silent --basic --user $SR_AUTH -X PUT -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '{\"compatibility\":\"NONE\"}' $SR_URL/config/$TOPIC-value | jq ."
curl --silent --basic --user $SR_AUTH -X PUT -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"compatibility":"NONE"}' $SR_URL/config/$TOPIC-value | jq .
read -p "Press enter to continue"

echo
echo -e "${GREEN}Try again -> {\"id\": \"111\",\"amount\": 10,\"newfield\": \"sample123\"}${NC}"
echo "kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --producer.config $PATH_TO_CCONFIG\
    --property schema.registry.basic.auth.user.info=$SR_AUTH \
    --property basic.auth.credentials.source=USER_INFO \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{\"type\": \"record\",\"name\": \"Payment\",\"namespace\": \"io.confluent.examples.clients.basicavro\",\"fields\": [{\"name\": \"id\",\"type\": \"string\"},{\"name\": \"amount\",\"type\": \"double\"},{\"name\": \"newfield\", \"type\": \"string\"}]}'"
kafka-avro-console-producer \
    --broker-list $KAFKA_URL \
    --producer.config $PATH_TO_CCONFIG\
    --property schema.registry.basic.auth.user.info=$SR_AUTH \
    --property basic.auth.credentials.source=USER_INFO \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --property value.schema='{"type": "record","name": "Payment","namespace": "io.confluent.examples.clients.basicavro","fields": [{"name": "id","type": "string"},{"name": "amount","type": "double"},{"name": "newfield", "type": "string"}]}' << EOF
{"id": "111","amount": 10,"newfield": "sample123"}
EOF
echo "{id: 111,amount: 10,newfield: sample123}"
read -p "Press enter to continue"

#------------------------------#
# Listing schema versions on our topic
#------------------------------#
echo
echo -e "${GREEN}List the number of versions${NC}"
echo "curl --silent --basic --user $SR_AUTH -X GET $SR_URL/subjects/$TOPIC-value/versions | jq ."
curl --silent --basic --user $SR_AUTH -X GET $SR_URL/subjects/$TOPIC-value/versions | jq .
read -p "Press enter to continue"

#------------------------------#
# Consume Avro messages
#------------------------------#
echo
echo -e "${GREEN}Consume the messages${NC}"
echo "kafka-avro-console-consumer --bootstrap-server $KAFKA_URL --property schema.registry.url=$SR_URL --topic $TOPIC --from-beginning"
kafka-avro-console-consumer \
    --bootstrap-server $KAFKA_URL \
    --consumer.config $PATH_TO_CCONFIG \
    --property schema.registry.basic.auth.user.info=$SR_AUTH \
    --property basic.auth.credentials.source=USER_INFO \
    --property schema.registry.url=$SR_URL \
    --topic $TOPIC \
    --from-beginning

echo -e "${GREEN}Fin${NC}"