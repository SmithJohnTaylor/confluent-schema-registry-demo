#!/bin/zsh

SR_AUTH=
SR_HOST=

#TODO usage menu
#TODO print warning this will delete all non-internal schemas
#TODO create tmp directory
#TODO create subjects file
#TODO read all current subjects, ignoring internal, and store in file

#delete all schemas in file
while read p; do
  eval curl -X DELETE -u $SR_AUTH $SR_HOST/subjects/$p
done <subjects.txt
