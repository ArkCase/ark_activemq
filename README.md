# ActiveMQ for Arkcase

Apache ActiveMQ® is the most popular open source, multi-protocol, Java-based message broker. It supports industry standard protocols so users get the benefits of client choices across a broad range of languages and platforms. Connect from clients written in JavaScript, C, C++, Python, .Net, and more. Integrate your multi-platform applications using the ubiquitous AMQP protocol. Exchange messages between your web applications using STOMP over websockets. Manage your IoT devices using MQTT. Support your existing JMS infrastructure and beyond. ActiveMQ offers the power and flexibility to support any messaging use-case.

ActiveMQ Documentation is available at https://activemq.apache.org/

## Runtime Instructions

In order to run the ActiveMQ container, you will need to provide the
complete set of configuration files required by ActiveMQ in the
`/app/conf` directory inside the container. For example, you could
deploy the container using a Helm chart and use a Kubernetes ConfigMap
or Secret to make those configuration files visible inside the
container. The [test/conf](test/conf) directory provide an example of
what the configuration files could look like.

## How to build:

docker build -t ark_activemq:latest .

Repository pushes occur automatically when code is checked in.

## How to run: (Helm)

helm repo add arkcase https://arkcase.github.io/ark_helm_charts/

helm install ark-activemq arkcase/ark-activemq

helm uninstall ark-activemq

## How to run: (Kubernetes)

kubectl create -f pod_ark_activemq.yaml

kubectl --namespace default port-forward activemq 8080:8161 --address='0.0.0.0'

kubectl exec -it pod/activemq -- bash

kubectl delete -f pod_ark_activemq.yaml

## How to run: (Docker)

docker run --name ark_activemq -p 8161:8161  -d 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_activemq:latest

docker exec -it ark_activemq /bin/bash

docker stop ark_activemq

docker rm ark_activemq

