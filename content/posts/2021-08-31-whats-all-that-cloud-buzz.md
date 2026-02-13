---
title: Cloud Services
author: Omer Dolev
date: 2021-08-31 16:26:00 +0800
categories: [Tech]
tags: [cloud, aws]
summary: "What cloud computing is, how billing works, and an overview of cloud service models (IaaS, PaaS, SaaS) with AWS as an example."
cover:
  image: "/img/whats-all-that-cloud-buzz-pic-1.png"
  alt: "Cloud Services Overview"
  hidden: false
---

## What's All That Cloud Buzz?!

One of the reasons so many new start-ups can try to make our life easier is "THE CLOUD".

Let's say you have an apartment, you have your living room, bedroom, bath room, kitchen and accessories. 
Suddenly, you get a deal from your work place, a 3 months vacation (a place eveyone would like to work at) to the caribbeans. During these 3 months, even if you are not effectively using your apartment, you still have to pay rent and additional bills and fees.  
In that case, what many would do is subletting their apartment, which means that they can make some money during their vacation and cover the expenses for their apartment.

Let's get a bit more technical.  
Say you are a company and you have a datacenter that for an irrelevant reason would have to stay inactive unless you somehow let people run workloads there. In that case you can cover expenses and might even get some profit out of it.

This is basically (very basically) what cloud is.  
There are companies that have a vast amount of compute resources. Those companies need lots of resources to run their own services and still they have so much more, that they lend those compute resources to other companies to run their services. It's working so well that there are companies worth Ms and even Bs of $ that run entirely in the cloud (in another company's datacenter).

Another thing that made cloud approachable is the accessability. All you need to do is just create an account, make sure there is a payment method and you can start using the cloud provider resources (providers - such as Google, Amazon and Microsoft - are the those that lend resources to other companies).

The billing model is also quite simple. The general concept is "pay for what you use". For example, if you run a server you pay for the time the server was running. In storage however, because storage is not "temporary" you pay the fare for a certain capacity usage (e.g. per gigabyte).  
Each service has a different billing model based on that.

And this is just the beginning, there are more complicated concepts that enable cost reduction, since you can acheive the same goal with many different architectures and solutions whose costs are different from one another. Things like burst capacity for CPU, Memory and even I/O, enable utilization peak tolerance (so instead of using more servers - that cost more money - you use the same ones, but still cope with the load). Others are reservations (of resources which decreases costs dramatically but requires planning), spot instances (resource scavenging) and multiple storage tiers.  
Overall, the way to manage costs is basically a good solution architecure (which integrates cost saving feature among the aforementioned).

The cloud is also very versatile, cloud providers (such as AWS) develop services with different levels of abstraction. In the cloud you will find IaaS (VPC, EC2), PaaS (S3, RDS), and SaaS (Lambda, DynamoDB) solutions including specific applications that you can use in a fully managed manner (and of course, the billing model might change according to the level of abstraction).

The infrastructure is also geographically distributed. The terminology might differ from provider to provider but the idea is the same. As companies have Ms or even Bs of end-users from all over the world, they need to be able to provide service to their end-users in a responsive, reliable, resilient, secure way.  
In AWS there are regions and mulitple zones (or availability zones - AZ) within a region. AWS services have different scopes, meaning, each service or service component operates within a geographic context (AZ, regional or global). For instance, EC2 is a regional service and each instance in EC2 is operating within a single AZ. S3 (AWS storage service) is global, but the components in this service called "buckets" are regional. IAM (Identity and Access Management) service is also global, as it is the service responsible for permissions and authentication.