#!/bin/bash
git clone https://github.com/tehCrush/dog_agent_ex.git
cd dog_agent_ex
git pull
git checkout main
cd ..

git clone https://github.com/tehCrush/dog_agent
cd dog_agent
git pull
git checkout feature/ansible_connection
cd ..

git clone https://github.com/tehCrush/dog_trainer
cd dog_trainer
git pull
git checkout feature/ansible_connection
cd ..

git clone https://github.com/tehCrush/dog_park
cd dog_park
git pull
cd ..

git clone https://github.com/tehCrush/csc.git
cd csc
git pull
cd ..

docker-compose -f docker-compose.local_deploy.yml build
docker-compose -f docker-compose.local_deploy.yml up

#docker container ls
