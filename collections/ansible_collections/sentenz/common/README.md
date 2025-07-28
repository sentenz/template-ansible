# Ansible Collection for Common

- [1. Roles](#1-roles)
  - [1.1. Container](#11-container)
    - [1.1.1. Docker](#111-docker)
      - [1.1.1.1. Details](#1111-details)
      - [1.1.1.2. Role](#1112-role)
  - [1.2. AWS](#12-aws)
    - [1.2.1. EBS Volume](#121-ebs-volume)
      - [1.2.1.1. Details](#1211-details)
      - [1.2.1.2. Role](#1212-role)

## 1. Roles

### 1.1. Container

#### 1.1.1. Docker

Docker Engine is an open source containerization technology for building and containerizing applications.

##### 1.1.1.1. Details

1. Compoments and Features

    - [Supported Platforms](https://docs.docker.com/engine/install/#supported-platforms)
      > Instructions to install Docker Engine on supported platforms.

      > [!NOTE]
      > Available as [Ansible Role](roles/container/docker/tasks/main.yml) in the Collection.

##### 1.1.1.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Common Container
        hosts: observability
        become: true
        roles:
          - role: sentenz.common.container.docker
      ```

### 1.2. AWS

#### 1.2.1. EBS Volume

Amazon Elastic Block Store (Amazon EBS) provides scalable, high-performance block storage resources, used with Amazon Elastic Compute Cloud (Amazon EC2) instances.

##### 1.2.1.1. Details

1. Compoments and Features

    - [Format and mount an attached volume](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-using-volumes.html)
      > Procedure to make the attached EBS volume for the root or data device available for an EC2 instance.

      > [!NOTE]
      > Available as [Ansible Role](roles/aws/ebs_volume/tasks/amazon.yml) in the Collection.

    - [Create a snapshot of an EBS volume](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-create-snapshot.html)
      > [!NOTE]
      > A ClickOps approach to creating snapshots of EBS volumes can be achieved through the AWS Management Console.

##### 1.2.1.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Common AWS
        hosts: observability
        become: true
        roles:
          - role: sentenz.common.aws.ebs_volume
      ```
