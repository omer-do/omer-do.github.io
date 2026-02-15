---
title: Container Runtimes (K8s series - 3)
author: Omer Dolev
date: 2020-12-11 16:50:00 +0800
categories: [Tech]
tags: [kubernetes, containers, infrastructure]
series: ["Kubernetes"]
summary: "What container runtimes are, the role of OCI standards, and the distinction between high-level and low-level runtimes."
---

Remember all the things we now know about containers?
So every time we want a container we need to create different namespaces and then spawn the process, and when the process exits we need to remove them all
and do some cleanup? NO...

This is what container runtimes are for. As you will see in a moment there are many runtimes, and they are usually called low-level or high-level runtimes.
One of the most famous container runtimes is Docker. But since Docker's release many changes took place in this field on container runtimes.

**_NOTE:_** All the data about container runtimes is based on Ian Lewis's [blog](https://www.ianlewis.org/).

## Let's start some containers! oh... wait...

Before we continue we need to understand how a runtime systemizes container creation. In the [previous post](https://omerdolev.github.io/posts/containers/)
we saw that containers are actually processes that live in different namespaces than the system ones. But there is one important thing we didn't mention.

If a container is a process, and the process spawns in a different mnt namespace (a different filesystem basically), don't we need the executable to be in the
filesystem that resides in that mnt namespace? 

The answer is yes. That's what ***images*** are for. A container image is usually a zipped file that contains a filesystem (comprised of different layers) with
an executable and all the files required for that executable to run, and some metadata for this image (for instance, maybe this executable should be run with arguments, maybe
some environment variables should be set). All this data and the filesystem is called an image.

So let's take Docker as an example. Docker was a single solution for container runtime. It had many functionalities that, at first, were all part of the Docker
product, but aren't really dependent on one another. For example:

- an image format
- a method for building images
- management of images
- management of running containers (including running containers)
- sharing container images

To standardize this, Docker, Google, CoreOS and other leaders in the container industry created the OCI (Open Container Initiative). Docker contributed a standard
way of running containers as a library called [runc](https://github.com/opencontainers/runc) to the OCI (and that's it, nothing pertaining images or management was
standardized by Docker for the OCI).

### High-level and Low-level Runtimes

If we list a few of the common container runtimes, we can see: runc, lxc, lmctfy, docker (containerd), rkt, cri-o.
Each one implements different functionalities in the runtime stack.

![runtimes_pic](/img/runtimes.png "Title")

High-level runtime is attributed to runtimes that aside from actually running the container are implementing image management, unpacking and image format,
as well as API for these operations.

Low-level runtime is attributed to runtimes that focus on just the part of running the container itself, those that actually use the features
of the underlying kernel (namespaces and cgroups in the case of Linux containers).

The thing is you can't really divide runtimes into high-level ones and low-level ones, since there are runtimes that implement the whole stack of functionality.

**_Fun Fact:_** cri-o and container-d are leaning more to the high-level side, and they both use runc as a low-level container runtime. So if you take a, say,
low-level runtime developer perspective, the high-level runtime isn't really a runtime. But from an SRE or developer POV, this is the interface to the container
management, so it kind of "wraps" the low-level runtime.


