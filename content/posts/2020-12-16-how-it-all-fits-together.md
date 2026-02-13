---
title: Kubernetes - How It Fits Together (K8s series - 6)
author: Omer Dolev
date: 2020-12-16 09:50:00 +0800
categories: [Tech]
tags: [kubernetes, containers, infrastructure]
series: ["Kubernetes"]
summary: "How pods leverage Linux namespaces to share environments between containers, plus a look at the Kubelet and Kube-proxy."
cover:
  image: "/img/how-it-all-fits-together-1.png"
  alt: "Kubernetes Architecture Overview"
  hidden: false
---

## Going to the Roots

There is much much more to talk about the control plane, but that's for more specific posts. Eventually, what we want to do in K8s is actually running workloads in the form of Pods.

What's a Pod? It's components? You can read about it from a high-level perspective in the [official documentation](https://kubernetes.io/docs/concepts/workloads/pods/).  
Rewinding back to the containers post, we remember that Linux containers are not really "containers" they are normal processes, executed using 2 features of the Linux Kernel: Namespaces and Control Groups (cgroups).

Pod is actually taking these namespaces and cgroups and leveraging them to make some cool stuff with "containers". Normally, people see pods like standalone boxes.

![Image2](/img/how-it-all-fits-together-2.png)

But there are cool things we can do with namespaces, and they have quite a flexible functionality.  
Let's create an nginx container and a ghost container in the same namespaces so they are able to talk to each other:

```
# conf file for the nginx
cat <<EOF >> nginx.conf

error_log stderr;
events { worker_connections  1024; }
http {
  access_log /dev/stdout combined;
  server {
    listen 80 default_server;
    server_name example.com www.example.com;
    location / {
      proxy_pass http://127.0.0.1:2368;
    }
  }
}
EOF

# let's create the nginx container
# in the case of the IPC namespace we need to run the first container with shareable IPC mode
docker run -d --ipc="shareable" --name nginx -v "$(pwd)"/nginx.conf:/etc/nginx/nginx.conf -p 8080:80 nginx

# now let's create the ghost container
# notice, we are sharing network, IPC, and PID namespaces with the nginx
# we can share more namespaces or less namespaces as we like
# but for the sake of the example lets share these 3
docker run -d --name ghost --net=container:nginx --ipc=container:nginx --pid=container:nginx ghost
```

After running these commands you can go visit http://localhost:8080/ and see the ghost page behind the Nginx we created.  
But let's break down what we have just done.

The Nginx is a container, living in its own network namespace. So 127.0.0.1 is the loopback address in the network namespace of the container.
Nginx is configured to listen to port 80, and the config says that when we get a request we forward it to http://127.0.0.1:2368, so we actually forward it to a different port (the ghost port).

Then we ran the ghost container and put it in the same net, PID and IPC namespaces as the Nginx container (I shared 3 namespaces even though just sharing the network one would work).

**_NOTE_**: In this example, even though sharing only the network namespace would work (try it yourself), sharing other namespaces (like PID, IPC, etc...) can be very useful for use-cases that require a certain level of IPC (inter-process communication) or data sharing.

So now that the containers are in the same net namespace, the 127.0.0.1 of the Nginx, is actually the 127.0.0.1 of the ghost as well. That's why this forwarding works.  
After sharing all the namespaces it would look something more like this:

![Image3](/img/how-it-all-fits-together-3.png)

So pods are almost like that, they combine namespaces with multiple processes. When K8s starts up a pod it's a bit more complicated as K8s uses CNI (container network interface, which we will talk about) and not docker networking, but the idea of sharing the environment (network, volumes - mounts, IPC - signals for example, processes, hostname...) is the same.  
A pod would look closer to something like this:

![Image4](/img/how-it-all-fits-together-4.png)

**_NOTE_**: For those who know K8s already the cgroup there is why you can configure resources per container in the pod spec.

One very good use-case for more than one container in a pod is service meshes for example. [Istio](https://istio.io/) (one of the most famous service meshes) usually implemented using what's called a side-car container.
Meaning that it "injects" another container to the pod, that runs along with the application pod and has a view into what's going on in the pods environment. The sidecar also acts as a gateway having every packet in and out of the pod go through it, letting it extract lots of data, while enabling smart and granular enforcement of net policies.

## The Kubelet and Kube-proxy

The only piece of the puzzle left, is what's going on the K8s Nodes. The nodes are servers that actually run the containers and the components running there are the Kubelet and the Kube-proxy.  
You might call them the K8s field agents :)

These are the pieces of K8s that do the field work.  
Specifically, the Kubelet is the component that on first startup registers the node into the cluster, interacts with the container runtime installed on the K8s node to run the pods, as well as reporting the status of the node and the pods running on it back to ETCD.  
The Kube-proxy, as its name implies, is more related to the network side, specifically to the K8s services (we will talk about that).

The CNI (the implementation for network in K8s) is usually a pod or a service that runs on the node (not included in Kubelet or Kube-proxy), which configures the overlay network.

**_Fun Fact_**: If you run *docker ps* on a K8s node, you might notice that there are more containers than you think. In particular, you will have an additional container for each pod whose name is k8s_POD... and it's command is /pause. This container has a few functionalities and it'll be discussed in a future post.

Here is a nice chart showing an overall view of kubernetes (image is link to K8s Docs page):

![Image5](/img/how-it-all-fits-together-5.png)
