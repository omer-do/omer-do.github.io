---
title: AWS Virtual Private Cloud
author: Omer Dolev
date: 2021-09-08 12:00:00 +0800
categories: [Tech]
tags: [cloud, aws, networking]
summary: "An introduction to AWS VPC — the foundation of cloud infrastructure, including CIDR ranges and regional scoping."
---

## Is My Private Cloud Real?

The VPC is the foundation of your infrastructure in the cloud. It's a general idea (used by providers) of a way you (the customer) can use the provider's resources. The following is going to be based on AWS (since that's what I have experience in). 
For that purpose you create a kind of an overlay network in their infrastructure and this network will contain all the resources and services you utilize. This network, its components and configurations comprise your Virtual Private Cloud (VPC).

The VPC is a REGIONAL service!  
Meaning, a single VPC cannot contain resources spanning across different regions. Once you choose the region for your VPC you configure a CIDR (Classless inter-domain routing) range for your network (e.g. 10.0.0.0/16).
From now on all the resources that have network interfaces will take their address from this range.