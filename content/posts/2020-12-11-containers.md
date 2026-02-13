---
title: Containers (K8s series - 2)
author: Omer Dolev
date: 2020-12-11 12:40:00 +0800
categories: [Tech]
tags: [kubernetes, containers, linux]
series: ["Kubernetes"]
summary: "A deep dive into what Linux containers actually are — namespaces, cgroups, and how they differ from virtual machines."
cover:
  image: "/img/containers-1.png"
  alt: "Linux Containers"
  hidden: false
---

Containers are awesome. At first they sound quite simple, but they enable many things that weren't possible before. Here I will explain what are containers in a bit of a deep-dive so you can truly understand what they are.

Containers are applications that are abstraced from the environment in which they run. This is the high-level explanation, which is of course correct but it's a bit vague and general. It is noteworthy that this abstraction is very useful for allowing applications to be deployed easily and consistently (that is regardless what machine the container runs on). What's more interesting is how containers are actually implemented (at least in Linux) and just how different they are from VMs.
Understanding how they are implemented in Linux will give you an idea about what they are and will help you understand the whole thing better as we move on to talk about K8s.

## Linux Containers (LXC)

The goal of containers is running workload decoupled from the underlying environment. Even though it's almost totally decoupled there is one thing that ties the container with the underlying machine, the machines **kernel**.

So Linux containers is an operating system virtualization mechanism for running multiple isolated Linux systems (which we call containers) on a host using a single Linux kernel.
This is done, using a feature of the Linux kernel called "Namespaces".

### Linux Namespaces

If you're familier with the term "namespaces" from programming (in GoLang for example it's called a "package"), it's a logical seperate area containing objects isolated from other areas in our code.

In Linux, a Linux namespace is a logical seperation of operating system resources. In Linux every namespace has a type which determines the type of resources this namespace can contain. For example, a network namespace will contain network interfaces and sockets, a UTS (Unix Timesharing System) namespace contains seperate hostname and domain name, an mnt (or mount) namespace is a set filesystem mounts visible within the namespace. There are other namespaces as well, and we will get to some of them.

Linux has system namespaces which are the main namespaces that all the processes in the system live in by default, and each process is bound to one namespace of each type.
When running containers we actually run a Linux process in namespaces other than the system ones, which means new namespaces for the process are created, and the process is attached to these namespaces.

Let's try, for example, playing with the network namespace. Let's start by viewing the existing ones and creating a new one (you might need *sudo* for those commands):

```bash
# create new net namespace
ip netns add nstest
# verify it was created using the following
ip netns list
```

Now remember this is a namespace seperated from the host system namespace.
We can now create a veth interfaces pair to connect the two namespaces.

```bash
# create v-eth1 and it's peer v-peer1
ip link add v-eth1 type veth peer name v-peer1
# see interfaces here
ip link show
# put v-peer1 in new network namespace
ip link set v-peer1 netns nstest
```

After this, we can set addresses for the interfaces and bring them up:

```bash
ip addr add 10.200.1.1/24 dev v-eth1
ip link set v-eth1 up
ip netns exec nstest ip addr add 10.200.1.2/24 dev v-peer1      # Notice that running regular ip commands is in the system namespace
ip netns exec nstest ip link set v-peer1 up                     # and to run the ip commands inside a namespace you need to add the
ip netns exec nstest ip link set lo up                          # ip netns exec <ns_name> before the command
```

OK! now we have a new net namespace and an interface up with an address of 10.200.1.2, also we brought the loopback interface up in nstest.

Now let's make a route to forward all traffic from nstest to the system namespace i.e. to v-eth1.

```bash
ip netns exec nstest ip route add default via 10.200.1.1        # This adds a route in the routing table to be, by default forwarded to v-eth1
```

We are almost there, but for the internet connection we want to enable forwarding in the system namespace and share internet access between the host and nstest.
This is done by enabling forwarding using the iptables interface.

```bash
echo 1 > /proc/sys/net/ipv4/ip_forward                       # by default there's a '0' there disabling this
iptables -P FORWARD DROP                                     # setting default policy in the FORWARD chain to DROP
iptables -F FORWARD                                          # flushing forward rules
iptables -t nat -F                                           # flushing nat rules
iptables -t nat -A POSTROUTING -s 10:200.1.0/255.255.255.0 -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o v-eth1 -j ACCEPT              # Allowing forwarding between eth0 and v-eth1
iptables -A FORWARD -o eth0 -i v-eth1 -j ACCEPT              # both ways
```

Awesome! Now let's try to see if we have a connection:

```bash
ip netns exec nstest ping 8.8.8.8

PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=50 time=48.6ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=50 time=52.1ms
```

**_NOTE:_** This network namespace game was inspired by https://blogs.igalia.com/dpino/2016/04/10/network-namespaces/

GREAT!

### Back to Containers

So we have an example for the net namespace, now a container is actually attached not only to a different net namespace but also to a different pid namespace (seeing a isolated pid tree), mnt namespace (seeing different mounts), uts namespace (seeing different hostname).
This collection of namespaces for a container, is called a container ***sandbox*** in some places.

Now you might think, wait... what about resources, as in CPU and memory. Containers are using the system resources as any other process. But we would also like to control how much resources a container uses, for that we have cgroups (Control Groups, which is another Linux kernel feature) which can cap the memory and CPU shares a process can use
(I will get into that in the resource management for K8s post).

Now an interesting question arises:
#### Can you run Windows containers on Linux hosts and vice-versa?

The short answer is no. But who likes short answers...

Containes use the host OS kernel (after all it's just a simple process) so when running a ***LINUX*** container it needs a ***LINUX*** kernel, and when running a ***WINDOWS*** container it requires a ***WINDOWS*** kernel.
However, you ***can*** run a ***LINUX*** container on a ***WINDOWS*** host since what happens behind the scenes is that Windows runs a Linux VM (read more [here](https://docs.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/linux-containers)).

So we spilt it out already... What is the difference between a container and a VM.

When running a VM, you are running a complete operating system, the kernel and user mode processes, meaning you boot it up, it does its checks and tests, it starts all the required processes just like as if you pushed the "on" button of your computer.

When running a container, you create a few namespaces (sometimes the namespaces will be present already), and you just spawn a process in those namespaces, which results in a much lighter, faster operation.

Still, there might be some cases in which you would like to use VMs of course. Let's say that your product is a cross-platform application, and you want to test it on all the common OSs and the last 4 versions of each, for that you will need to run different kernels (operating systems) and test your product on them. Containers are not the correct solution for this use-case. Though for Saas use-cases, containers is mainly the way to go.
