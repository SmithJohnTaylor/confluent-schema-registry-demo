## Step-by-step walk through of the demo script
0. Define your kafka broker endpoint and your schema registry address at the top of the `schema-demo.sh` file.
1. Invoke the script with the follwing command: `./schema-demo.sh <insertyourtopicname>`
1. The script will use the kafka-topics command to create the new topic.
    - this script assumes a single node. if you have multiple brokers, you may need to increase the replication factor. 
1. The script will list all the topics 
    - will exclude internal topics with a leading underscore `_` 
1. The script will list all of the subjects and schemas. We will be focusing on value schemas, so our schemas will be appended with `-value`
1. The script will query the Schema Registry for the global compatibility of the schemas. By default this is `BACKWARD` compatibility
1. Next we are going to register a new schema manually using a REST call. 
    - First, we will display the schema
    - Then we will make the REST call

    **This call returns a schema ID for the registered schema. If the Schema Registry determines the exact same schema is already registered, the Schema Registry will return the ID for the already registered schema and associate it with our topic.**
1. The script will list the number of schema versions for our topic
1. The script will query the Schema Registry for the latest version of the schema on our topic
1. The script will query for the compatibility of our schema. By default, it inherets the global compatibility.
1. The script will produce to our topic using our registered schema.
1. The script will now attempt to publish using a new, evloved schema that includes an additional field. *This will fail*
    - This new schema is not backwards compatible as it doesn't provide a default value for the new field. 
1. The script will make a REST call to modify the schemas compatibilty for our topic to be `NONE`
1. The script will try again to produce with the new schema, and this will be successful thanks to the compatibility change.
    - considerations should be made about compatibilty requirements for each use case.
1. The script will list the schema versions on the topic and we will see that we have two.
1. Lastly, the script will consume the avro messages, and you can see that it successfully consumes messages with both schemas. This is because an avro message provides the schema id for the consumer to know which schema to leverage for the messages.