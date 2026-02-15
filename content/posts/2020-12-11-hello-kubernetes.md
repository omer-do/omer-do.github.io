---
title: Hello Kubernetes (K8s series - 1)
author: Omer Dolev
date: 2020-12-11 10:10:00 +0800
categories: [Tech]
tags: [kubernetes, containers, infrastructure]
series: ["Kubernetes"]
summary: "An introduction to Kubernetes — what it is, how deployments evolved from physical servers to containers, and why container orchestration matters."
cover:
  image: "/img/hello-kubernetes-1.png"
  alt: "Hello Kubernetes"
  hidden: false
---

Kubernetes is a very big subject. I know people that have been working with it for years, and still don't have a good grasp on what's going on in certain parts.
In the next few posts (a Kubernetes series) I will go over the things I know about Kubernetes. We will delve into different concepts as we continue on.

**_NOTE:_** From now on I will mostly write "K8s" instead of "Kubernetes".

## What is Kubernetes?

**_Fun Fact:_** The name Kubernetes is from Greek, meaning helmsman or pilot (see K8s docs).

To find an answer to that question you can visit K8s docs, but if you are already here then, K8s is summed up most of the times as a container orchestrator.
When you look at it pragmatically it's what most of the job of K8s is, running containers. But in reality it's much much more than that.

There are many different factors embedded in the notion of running containers, and K8s lets you control that if you like. Making things flexible when needed but it also
enables automation.

We can start understanding things if we look at the state things were before container orchestration solutions were common. We are actually talking about how things were
deployed and running over time.

**_NOTE:_** When writing "workload", I mean anything that does processing, anything that runs code or runs some sort of logic, whether it is handling requests, doing some async processing etc.

#### Traditional Deployments

Running workloads on physical servers. There are lots of problems with this approach which will be described later (of course it's easy to discern retro), but for now let's continue.

#### Virtualized Deployments

Virtualization is a way to run multiple virtual machines (VMs) on one physical server. This is actually running multiple Operating systems (Linux, Windows, Embedded or whatever) concurrently on the same physical machine that are independent of one another. This was the time when deploying virtual machines running the different applications and services was common.

#### Containerized Deployments

Deployment of workloads as containers. We will have a post about what are containers exactly. For now let's think about them as very lightweight VMs. This is the present, in which deployment of applications on containers is very common.


So now, in a time where running applications is mainly done by containers, there is something very important to keep in mind, and it's the availability of your application.
When an application experiences a fault or a panic in the [Traditional Deployments](#traditional-deployments) era, the relevant team would be alerted and would go straight to the server to fix, and later will try to understand what happened (in this case most of fixes are restarts).
The same thing holds for VMs ([Virtualized Deployments](#virtualized-deployments)), where your relevant team would check the problem, fix, and try to understand the root cause.

But, in the [containers](#containerized-deployments) era something changed. A new outlook surfaced, in which workloads are **volatile**. It became very easy to just start a new container running the required workload instead of trying to fix the problem while there is downtime or degraded availability (downtime - when the service is unavailable).

This is where K8s comes in, it provides you with a framework and tools to run distributed systems resiliently.
Distributed systems are systems or a group of workloads that run on a number of machines (can range from a few to dozens and hundreds or more), which in its simplest form can technically be achieved quite easily (it gets complicated when new use-cases arise, but we'll get into that).

K8s gives you:

- **Service discovery and load balancing** which we will get into when we talk about networking in K8s.

- **Storage orchestration**

- **Automated rollouts and rollbacks** and lots of deployment practices

- **Self healing** ensuring availability

- **Secret and configuration management**

There are lots of things to think about when running distributed systems, K8s is based on loads of experience Google has in this field.
The thing I like most is that while working with K8s there were many light bulbs that went on in my head, and writing this blog also helps me learn more about it.
