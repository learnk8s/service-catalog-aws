# Setting up the Service Catalog

A step-by-step guide on how to set up the Service Catalogue in Amazon Web Services (AWS).

## Prerequisites

- You should have a running cluster.
- You should have `kubectl` connected to the cluster.
- [You should have Helm 3 installed](https://helm.sh/docs/intro/install/).
- [You should have the AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html).

## Installing the Service Catalog

Create a namespace for the Service Catalog with:

```bash
kubectl create ns catalog
```

Add the chart repository to Helm with:

```bash
helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
```

Install the Service Catalog with:

```bash
helm install catalog svc-cat/catalog --namespace catalog --wait
```

You should find two Pods running in the namespace:

```bash
kubectl get pods --namespace catalog
```

The two Pods are:

- The Catalog API Server and
- The Catalog Controller Manager.

## Installing the AWS operator

Before you can install the Service Catalog, you need to create a user in AWS.

The user will create the resources on your behalf.

You also need a DynamoDB table to keep track of which services are used and other metadata.

You can inspect the [Cloudformation template](prerequisites.yaml) or [read the documentation](https://github.com/awslabs/aws-servicebroker/blob/master/docs/install_prereqs.md) to learn more about the prerequisites.

The repository contains a convenient script to get started.

You can launch the script with:

```bash
./aws-run.sh create us-west-2
```

The script terminates with an output similar to this:

```bash
{
  "KEY_ID": "RANDOMKEYID",
  "SECRET_ACCESS_KEY": "secretaccesskey"
}
Stack ID: arn:aws:cloudformation:us-west-2:415741118XXX ...
```

Make a note of the values as you need them in the next step.

You install the Service Broker with the identity that you created previously with:

```bash
helm install sb aws-sb/aws-servicebroker \
  --wait \
  --namespace catalog \
  --set aws.region=us-west-2 \
  --set aws.accesskeyid=<THIS_IS_THE_KEY_ID> \
  --set aws.secretkey=<THIS_IS_THE_SECRET_ACCESS_KEY>
```

If the deployment is successful, you should see one more deployed in the same namespace.

```bash
$ kubectl get pods --namespace catalog
NAMESPACE     NAME                                                  READY   STATUS    RESTARTS   AGE
catalog       catalog-catalog-apiserver-5645f8c86f-9tcv6            2/2     Running   0          168m
catalog       catalog-catalog-controller-manager-79b98447d9-bjmsp   1/1     Running   0          168m
catalog       sb-aws-servicebroker-77655c5dd5-s5k5l                 1/1     Running   0          151m
```

The new Pod is the AWS Service broker — the component that maps resources in your Kubernetes cluster to resources in Amazon Web Services.

You can verify that the Service Broker is correctly configured by tailing the logs:

```bash
kubectl logs <service broker pod id> --namespace catalog
```

You should see something similar to this:

```bash
I0324 04:52:50.821463       Updating listings cache with [{/athena true} {/auroramysql true} ...
I0324 04:52:51.054182       1 awsbroker.go:215] converting service definition "athena"
I0324 04:52:51.054282       1 awsbroker.go:355] done converting service definition "athena"
I0324 04:52:51.054300       1 adapter.go:37] putting service definition "athena" into dynamdb
I0324 04:52:51.091798       1 adapter.go:61] done putting service definition "athena" into dynamdb
```

The Broker is correctly configured and is listing services in the DynamoDB table.

You can list all the available managed services in your cluster with:

```bash
kubectl get ClusterServiceClasses
```

## Tidy up

You can delete the Cloudformation stack with the following command:

```bash
./aws-run.sh delete us-west-2 <replace with stack id>
```

## Useful links

- The original tutorial from AWS is [available here](https://aws.amazon.com/blogs/opensource/kubernetes-service-catalog-aws-service-broker-on-eks/).
- [The AWS Service Broker getting started guide](https://github.com/awslabs/aws-servicebroker/blob/master/docs/getting-started-k8s.md)
