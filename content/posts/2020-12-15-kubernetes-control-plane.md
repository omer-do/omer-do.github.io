---
title: Kubernetes Control Plane (K8s series - 5)
author: Omer Dolev
date: 2020-12-15 09:50:00 +0800
categories: [Tech]
tags: [kubernetes, containers, infrastructure]
series: ["Kubernetes"]
summary: "How the Kubernetes control plane works — etcd, the API server, controllers, and the scheduler."
cover:
  image: "/img/kubernetes-control-plane-4.png"
  alt: "Kubernetes Control Plane"
  hidden: false
---

## Overview

In K8s, as in many other products the architecture is a manager/master and worker nodes architecture.

I'm not going to cover everything in just one post, so for now let's focus on the control plane.  
If you needed to manage something like this, orchestrating containers, in a very large scale (hundreds to thousands of containers), how would you do it?

That's a very big question. But, let's break it down to simpler objectives or tasks.  

Let's start with the basis for this application. The first thing we might ask ourselves is how would this application know what to do? When to do it? And what to do it to?  
At the lowest level, a good way to start, is to somehow know the objective (the desired state), and find our way of getting to this desired state. Basically we need a place to hold our objective,
components will be able to check what the desired state is and then decide what actions need to be taken to get us there.

OK then! This application would have a part that does the work, and it needs a place for data.  
We will need a "single source of truth" (if we have more than one place where the desired state resides and somehow these different places hold different states, we will have chaos).
This single source of truth will have to be accessible to every component.
Also, to handle such scale, it needs to be distributed because we might need many worker nodes, doing loads of actions, also the control plane parts are going to perform many administrative actions as well.

There is another point here. Let's say we got our database, if many different components will have to perform operations on it, then we will be compelled to not only have logic in each component that connects to the database, we will also have to make sure that the operations are valid (so we don't have any corruption).  
Doing these validations and support large operations scale is not an easy task.
So, we should also have some kind of a gateway, via which components can access the data. It's easier to validate data, manage, and control.
In addition, it's also good if we have a standard way of interactions between components, so we should maybe consider having RESTful components.

## ETCD & API

![Image2](/img/kubernetes-control-plane-2.png)

That's where ETCD and the API server of K8s come into play. ETCD is a RESTful hierarchical distributed key-value datastore that can handle large scales (highly available), supports watching (watching for changes of entries)
and secure connections.

**_Fun Fact_**: ETCD uses the raft consensus algorithm to create a quorum for leader election. The leader is the member through which writes are committed to ensure consistency between members' data.
I will have a post about raft, as it's a cool algorithm that many tools use.

The API server is the gateway to the ETCD, all operations and changes to the desired state are going through the API server whose job is not only to perform them but to also validate, ensure the standardization
of data and structures and check authentication and authorization to perform such actions. It's also designed to be scaled up horizontally, to support high traffic.

Hurray! We have our truth source and the gateway to it :)

What we need now is the tools that will actually make the actions.  
What actions are we talking about though? Well...  
Checking the desired state and the actual state and bringing the actual state closer to the desired one.

Also, we need to know what we are going to manage.  
The managees are the K8s resources presented below:

![Image3](/img/kubernetes-control-plane-3.png)

## Controller and Scheduler

The doers of the control plane: the controller manager, and the scheduler.

### Like Controlling Stuff?

The controller manager is responsible for the controllers, the parts that really do stuff. So what's a controller?

A very good explanation is in the [K8s official Docs](https://kubernetes.io/docs/admin/kube-controller-manager/):

> In applications of robotics and automation, a control loop is a non-terminating loop that regulates the state of the system. In Kubernetes, a controller is a control loop that watches the shared state of the cluster through the API server and makes changes attempting to move the current state towards the desired state. Examples of controllers that ship with Kubernetes today are the replication controller, endpoints controller, namespace controller, and serviceaccounts controller.

In this excerpt (^^) some controllers are mentioned, and though it seems that controllers are exclusively handling a single resource, they are not. Controller are more "actions" oriented. Maybe actions sometimes involve a single object or resource type, but sometimes it's not like that. For example take a look at the [Tokens Controller](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#token-controller) and its [Github](https://github.com/kubernetes/kubernetes/blob/master/pkg/controller/serviceaccount/tokens_controller.go) if you'd like.

So, a controller checks if there are ways that the desired and actual state are different, then it does what's called a *reconcile* which is "bringing the current state to the desired state".
These "reconcile" actions are done differently and independently by different controllers.

The 2 main components of a controller are an Informer/SharedInformer and a WorkQueue.  
The Informer is a structure that holds a few things.
* a local **cache** where the controller can watch a list of resources and their changes in state (whenever an object is deleted, modified or created)
* **resource event handler** that configures an AddFunc (for when an object is added), an UpdateFunc (for when an object is updated) and a DeleteFunc(for when an object is deleted)
* **resync period** which sets an interval for when the controller should trigger the UpdateFunc on the items remaining in the cache. This provides a kind of configuration to periodically verify the current state and make it like the desired state. It's extremely useful in the case where the controller may have missed updates or prior actions failed.

SharedInformer is just like a regular informer but it's shared (as its name implies) among controllers. To share caches that watch resources eliminates duplication of cached resources, saves connections and improves overall costs for the 'watch' action.

Most controllers are using the SharedInformer. So they share the cached list of resources they need to watch, but the actions they want to perform for each change is different. So you can't have the same logic running in all the controllers that look at *deployments* for example. That's why each controller has a WorkQueue, whenever a resource changes the event handler pushes a key to the WorkQueue. The controller reads off this queue and handles the reconciliation.

### About Scheduling

The scheduler is in charge of assigning pods to nodes. Sounds EZ right? not that simple... (also read Julia Evans [post](https://jvns.ca/blog/2017/07/27/how-does-the-kubernetes-scheduler-work/) about the scheduler and the [github](https://github.com/kubernetes/kubernetes/blob/989b2fd3715d01a7757e891de2a17de5a5c2cc91/pkg/scheduler/scheduler.go))

The scheduler is a kind of a controller. The desired state is that every pod has a node assigned to it, it looks for pods without nodes, and tries to make actions towards the desired state (assigning them to nodes).

We could imagine the control loop like so

```python
while True:
    pods = get_all_pods()
    for pod in pods:
        if pod.node == nil:
            assignNode(pod)
```

It's not exactly like that though...

After a little bit of digging, what actually happens inside the scheduler is:

1. every pod that needs scheduling gets added to a queue (the only resources scheduled are pods)
2. when a new pod is created it also gets added to the queue
3. the scheduler takes pods of the queue, and schedules them

But what happens if a pod fails? If there is an error when scheduling the pod, it calls an error handler, and the error handler puts it back in the queue.

Ok wait... isn't the previous Python implementation better? for performance reasons, no...  
For more info about scheduling optimizations read at the following: [CoreOS - Improving Kubernetes Scheduler Performance](https://coreos.com/blog/improving-kubernetes-scheduler-performance.html)

**_Fun Fact_**: The scheduler uses an Informer too (like controllers usually do)

**_Another Fun Fact_**: The scheduler unlike controllers, doesn't resync. and that's something that was decided by the maintainers:
> @brendandburns - what is it supposed to fix? I’m really against having such small resync periods, because it will significantly affect performance.

and
> I agree with @wojtek-t . If resync ever fixes a problem, it means there is an underlying correctness bug that we are hiding. I do not think resync is the right solution.

To sum up, the overall architecture looks roughly like so:

![Image4](/img/kubernetes-control-plane-1.png)
