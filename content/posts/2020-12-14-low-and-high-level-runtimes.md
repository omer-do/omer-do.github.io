---
title: Low and High Level Container Runtimes (K8s series - 4)
author: Omer Dolev
date: 2020-12-14 09:50:00 +0800
categories: [Tech]
tags: [kubernetes, containers, infrastructure]
series: ["Kubernetes"]
summary: "Hands-on exploration of low-level container runtimes (cgroups, namespaces, runc) and high-level runtimes (Docker, containerd)."
cover:
  image: "/img/low-and-high-level-runtimes-1.png"
  alt: "Low and High Level Container Runtimes"
  hidden: false
---

Let's have a short dive into the world of container runtimes, talking about low-level and high-level runtimes (which from now will be referred to
as low-level runtimes and high-level runtimes).  

As mentioned in the previous post, conatiners (in Linux of course) are implemented by Linux namespaces and cgroups. Namespaces help you virtualize
the environment while cgroups helps you limit resources consumed by a process. The main responsibility of the low-level runtimes is the creation and
configuration of such namespaces and cgroups for containers, and then execution inside those namespaces and cgroups (this is the core functionality
of the low-level runtimes, which usually implement more features).

# Let's Go Low :)

**_NOTE:_** Based on Ian Lewis [post](https://www.ianlewis.org/en/container-runtimes-part-2-anatomy-low-level-contai)

I am working on Ubuntu, so to control cgroups you need to run the following (all the cg* commands will probably require sudo):

```bash
# install cgroups control commands
sudo apt-get install libcgroup-tools bc
```

We will use a simple container FS as our base FS for our container:

```bash
# creating a sample container and exporting it's FS to a tmp dir
CID=$(docker create busybox)
ROOTFS=$(mktemp -d)
docker export $CID | tar -xf - -C $ROOTFS
```

We will now create cgroups and limit resources for the container:

```bash
# creating cgroups - cpu and memory
UUID=$(uuidgen)
cgcreate -g cpu,memory:$UUID

# configuring memory limit to 100000000 bytes (100MB)
cgset -r memory.limit_in_bytes=100000000 $UUID
# configuring cpu shares to 512
cgset -r cpu.shares=512 $UUID
# we will use the cfs mechanism here (will be explained in a seperate post)
cgset -r cpu.cfs_period_us=1000000 $UUID
cgset -r cpu.cfs_quota_us=2000000 $UUID
```

OK! We create our container sandbox! Lets execute a command in the container:

```bash
$ cgexec -g cpu,memory:$UUID \
>     unshare -uinpUrf --mount-proc \
>     sh -c "/bin/hostname $UUID && chroot $ROOTFS /bin/sh"
/ # echo "Hello from in a container"
Hello from in a container
/ # exit
```

* The unshare command is used to execute a process in different namespaces

Now to clean up, let's delete our cgroups and tmp dir:

```bash
cgdelete -r -g cpu,memory:$UUID
rm -r $ROOTFS
```

One of the most common low-level container runtimes is [*runc*](https://github.com/opencontainers/*runc*) (which by the way, is written in GoLang).  
*runc* implements the OCI runtime spec, so for running a container with *runc* you need a root FS for the container, and a config.json file.

Let's run a container with *runc*:

```bash
# install *runc* in case it's not installed
sudo apt-get install runc
# create root dir for the container and export a sample FS
mkdir rootfs
docker export $(docker create busybox) | tar -xf - -C rootfs
```

Now let's create this config.json file:

```bash
# the following will create a config.json in your current dir
runc spec
# check the file out
cat config.json
{
        "ociVersion": "1.0.0",
        "process": {
                "terminal": true,
                "user": {
                        "uid": 0,
                        "gid": 0
                },
                "args": [
...
```

*runc*, by default, runs an sh command in a container with root FS at ./rootfs which just so happens to be our current setup :)  
So we can just use *runc*:

```bash
# run the container with config.json and ./rootfs which are in our current dir
sudo runc run mylovelycontainerid
/ # echo what a nice container
what a nice container
/ #
```

There are also other container runtimes you can use such as lmctfy and rkt, but for now let's continue on.

**_Fun Fact:_** In addition, there's [systemd-nspawn](https://wiki.archlinux.org/index.php/Systemd-nspawn) which enables runnning a command or even an OS in a light-weight namespace container, it resembles the chroot command (which changes your root dir) from a user POV, but actually, it fully virtualizes the FS as well as the hostname,
process tree and various IPC subsystems.

# Getting Back Up

High-level container runtime functionality is not really about running the container, it is more about the format and management of images, then passing it over to the low-level runtime to actually run the container.
Usually these runtimes will provide a daemon layer, or an API to perform those image and container management actions.
Since low-level runtimes are more concerned with the container itself, there are also high-level runtimes features that concern a collection of containers (for example, if I want a group of containers to share a network namespace).

Docker is one of the most common high-level container runtime which originally was developed as a monolith (both low and high level functionalities) client-server oriented daemon (dockerd and docker client) that provides image management, container management and execution along with an API.  
Those pieces of high and low level functionalities were divided into separate projects: *runc* (low-level) and containerd(high-level).

![Image2](/img/low-and-high-level-runtimes-2.png)

*dockerd* provides features such as building images, and *dockerd* uses *docker-containerd* to provide features such as image management and running containers. For instance, Docker's build step is actually just some logic that interprets a Dockerfile, runs the necessary commands in a container using *containerd*, and saves the resulting container file system as an image.

*containerd* architecture implies that it provides a gRPC API to be wrapped by higher layers, giving them image pull and push, management of storage, network interfaces, primitives and namespaces management, and as expected, using *runc* as the runtime.

![Image3](/img/low-and-high-level-runtimes-3.png)

*containerd* has a client cli called containerd-ctr (the command itself is *ctr*) usually used for debugging and development.

Another component people sometimes miss is *container-shim*. Which helps solving the daemon-ed containers problem. By daemon-ed container problem, I mean, that when *dockerd* is running a container, the container is now a child process of *dockerd*, so *dockerd* has to keep running for the container to keep running. What if I want to upgrade Docker (and inheritingly *dockerd*)? Also, how do I get the exit code of the container? What are the file descriptors (stdin, stdout and stderr) of the container?

For that *container-shim* exists. When runtimes start the container, *containerd-shim* allows *runc* to exit because it's there to be the parent of the container when *runc* exits. It keeps the file descriptors open in case containerd or dockerd die for some reason. Also it allow the container exit code to be reported back to a higher level tool (Docker for example) without it having to be the parent of the container and wait for it to exit.

## So let's see it in practice

```bash
ps fxa | grep docker -A 3  

2500 ?        Ssl    0:27 /usr/bin/dockerd -H unix:///var/run/docker.sock
2556 ?        Ssl    0:18  \_ docker-containerd -l unix:///var/run/docker/libcontainerd/docker-containerd.sock
...
```

Now let's try to run a simple container:

```bash
docker run -d alpine sleep 60

ps fxa | grep dockerd -A 3

2500 ?        Ssl    0:27 /usr/bin/dockerd -H unix:///var/run/docker.sock
2556 ?        Ssl    0:18  \_ docker-containerd -l unix:///var/run/docker/libcontainerd/docker-containerd.sock
8777 ?        Sl     0:00      \_ docker-containerd-shim 3da7... /var/run/docker/libcontainerd/3da7.. docker-runc  
8745 ?        Ss     0:00          \_ sleep 60  
...
```

So the "chain of command" is:

dockerd --> containerd --> containerd-shim --> "sleep 60" (desired process in the container).

* *runc* is not in the chain, cause it exited after starting the container :)
