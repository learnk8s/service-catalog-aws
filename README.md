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

Please note that, if you see the following output, you didn't configure the credentials correctly:

```bash
E0325 05:47:10.939633       1 api.go:30] Failed to fetch "/athena" from the cache, item not found
E0325 05:47:10.939639       1 api.go:30] Failed to fetch "/auroramysql" from the cache, item not found
E0325 05:47:10.939644       1 api.go:30] Failed to fetch "/aurorapostgresql" from the cache, item not found
```

You can list all the available managed services in your cluster with:

```bash
kubectl get ClusterServiceClasses
NAME                                   EXTERNAL-NAME      BROKER   AGE
023191a2-4337-5e62-800d-33739fe13046   codecommit         sb       10s
079bab7e-5fb3-5e50-a91a-46ce25ec44d5   elasticsearch      sb       9s
0bfa8323-b8db-5f27-b2ea-9b8f70e93767   emr                sb       9s
1bd1e315-91ab-5731-88ea-b29b82fc420c   rdsoracle          sb       7s
20ac3b60-8526-5327-9ea3-4f7893bed097   dynamodb           sb       10s
3e825f47-29ad-5099-8d4c-6d491548d0dd   kms                sb       9s
3ede66e0-519a-585f-917e-67c4ec86098b   documentdb         sb       10s
45df6868-5d9b-5d78-af9d-aa4f22a2b77e   elasticache        sb       10s
4741748c-1d32-5f86-81e9-857e3ed0b0f0   mq                 sb       8s
499aa9c6-085f-5e46-9c59-f063acb20538   sns                sb       6s
7a67ea0f-e7c6-532a-8466-8c2049f6369f   kinesis            sb       9s
7ebb7cf5-3a5c-52ca-a87a-688e766c65ca   lex                sb       9s
948dfdd0-dbb3-5bbe-b418-9d58daa2782f   translate          sb       6s
9ff60dab-f1de-53c7-baf4-47c70ed95419   redshift           sb       7s
a4b3ba4f-f53f-5469-81e5-efa61f65be40   aurorapostgresql   sb       10s
ad60756e-7482-5077-9883-2fe99ec45fd4   route53            sb       7s
b7ca6a1e-dee6-560e-b820-4a2259cd6de0   rekognition        sb       7s
baa70642-2fab-5615-ad19-05885f2be690   rdsmysql           sb       8s
ca3e9a89-0310-530b-8a5d-21ef88888822   s3                 sb       6s
cf1eda6f-8515-5d75-ba12-4a82c283d30d   sqs                sb       6s
d56a51f6-75f2-5f42-a613-3d9aff5e33f1   rdsmariadb         sb       8s
e15beaa5-e813-5b58-aa27-0b1f61d91a80   rdspostgresql      sb       7s
e396da29-6811-52cf-812c-75bb1902562b   athena             sb       10s
ec4bf8dd-8c12-50c3-bcfc-a45f722218f3   auroramysql        sb       10s
f4b249ea-71ea-59dd-9d0b-4f7f1c651b5d   rdsmssql           sb       8s
fbf8eeee-e9a9-54eb-b290-e8abb046b080   polly              sb       8s
ff28ec02-2efd-5fed-9e22-f53ac485d294   cognito            sb       10s
```

## Tidy up

You can delete the Cloudformation stack with the following command:

```bash
./aws-run.sh delete us-west-2 <replace with stack id>
```

## Useful links

- The original tutorial from AWS is [available here](https://aws.amazon.com/blogs/opensource/kubernetes-service-catalog-aws-service-broker-on-eks/).
- [The AWS Service Broker getting started guide](https://github.com/awslabs/aws-servicebroker/blob/master/docs/getting-started-k8s.md)
- [Official documentation on how to install the Service Catalogue](https://github.com/kubernetes-sigs/service-catalog/blob/master/docs/install.md)