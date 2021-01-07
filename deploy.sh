#!/bin/bash

rsync -avz -e ssh --stats --progress --delete . \
  --exclude "build" \
  --exclude ".git" \
  --exclude "node_modules" \
  k8s.moon:Development/devops/imagedb-init

ssh k8s.moon \
  'cd Development/devops/imagedb-init ;\
   sudo docker build -t imagedb-init . ;\
   sudo docker image tag imagedb-init registry.moon:80/imagedb-init ;\
   sudo docker push registry.moon:80/imagedb-init ;\
   kubectl -n moon rollout restart deployment imagestore'


