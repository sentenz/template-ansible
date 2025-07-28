# Ansible Collection for Observabilty

- [1. Roles](#1-roles)
  - [1.1. Grafana](#11-grafana)
    - [1.1.1. Grafana](#111-grafana)
      - [1.1.1.1. Details](#1111-details)
      - [1.1.1.2. Role](#1112-role)
    - [1.1.2. Loki](#112-loki)
      - [1.1.2.1. Details](#1121-details)
      - [1.1.2.2. Role](#1122-role)
    - [1.1.3. Promtail](#113-promtail)
      - [1.1.3.1. Details](#1131-details)
      - [1.1.3.2. Role](#1132-role)
  - [1.2. Prometheus](#12-prometheus)
    - [1.2.1. Prometheus](#121-prometheus)
      - [1.2.1.1. Details](#1211-details)
      - [1.2.1.2. Role](#1212-role)
    - [1.2.2. Node Exporter](#122-node-exporter)
      - [1.2.2.1. Details](#1221-details)
      - [1.2.2.2. Role](#1222-role)
    - [1.2.3. Alertmanager](#123-alertmanager)
      - [1.2.3.1. Details](#1231-details)
      - [1.2.3.2. Role](#1232-role)

## 1. Roles

### 1.1. Grafana

The open and composable observability and data visualization platform. Visualize metrics, logs, and traces from multiple sources like Prometheus, Loki, Elasticsearch, InfluxDB, and Postgres.

#### 1.1.1. Grafana

##### 1.1.1.1. Details

1. Compoments and Features

    - [Grafana](https://github.com/grafana/grafana)
      > Grafana the platform for monitoring and observability to query, visualize, alert on metrics.

      > [!NOTE]
      > Available as [Ansible Role](roles/grafana/grafana/tasks/main.yml) in the Collection.

    - [Grafana](https://hub.docker.com/r/grafana/grafana) Docker Hub
      > The official Grafana docker container.

##### 1.1.1.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Observability
        hosts: observability
        become: true
        roles:
          - role: sentenz.observability.grafana.grafana
      ```

#### 1.1.2. Loki

##### 1.1.2.1. Details

1. Compoments and Features

    - [Loki](https://github.com/grafana/loki)
      > Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system.

      > [!NOTE]
      > Available as [Ansible Role](roles/grafana/loki/tasks/main.yml) in the Collection.

    - [Loki](https://hub.docker.com/r/grafana/loki) Docker Hub
      > The Cloud Native Log Aggregation by Grafana.

##### 1.1.2.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Observability
        hosts: observability
        become: true
        roles:
          - role: sentenz.observability.grafana.loki
      ```

#### 1.1.3. Promtail

> [!CAUTION]
> Promtail is deprecated and will be replaced by [Grafana Alloy](https://grafana.com/docs/loki/latest/setup/migrate/migrate-to-alloy/).

##### 1.1.3.1. Details

1. Compoments and Features

    - [Promtail](https://github.com/grafana/loki)
      > Promtail is an agent which tails log files and pushes them to Loki.

      > [!NOTE]
      > Available as [Ansible Role](roles/grafana/promtail/tasks/main.yml) in the Collection.

    - [Promtail](https://hub.docker.com/r/grafana/promtail) Docker Hub
      > The official Promtail docker container.

##### 1.1.3.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Observability
        hosts: observability
        become: true
        roles:
          - role: sentenz.observability.grafana.promtail
      ```

### 1.2. Prometheus

The Prometheus monitoring system and time series database.

#### 1.2.1. Prometheus

##### 1.2.1.1. Details

1. Compoments and Features

    - [Prometheus](https://github.com/prometheus/prometheus)
      > Prometheus, a Cloud Native Computing Foundation project, is a systems and service monitoring system.

      > [!NOTE]
      > Available as [Ansible Role](roles/prometheus/prometheus/tasks/main.yml) in the Collection.

    - [Prometheus](https://hub.docker.com/r/prom/prometheus/) Docker Hub
      > The official Prometheus docker container.

##### 1.2.1.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Observability
        hosts: observability
        become: true
        roles:
          - role: sentenz.observability.prometheus.prometheus
      ```

#### 1.2.2. Node Exporter

##### 1.2.2.1. Details

1. Compoments and Features

    - [Node Exporter](https://github.com/prometheus/node_exporter)
      > Prometheus exporter for hardware and OS metrics exposed by *NIX kernels, with pluggable metric collectors.

      > [!NOTE]
      > Available as [Ansible Role](roles/prometheus/node_exporter/tasks/main.yml) in the Collection.

    - [Node Exporter](https://hub.docker.com/r/prom/node-exporter) Docker Hub
      > The official Node Exporter docker container.

##### 1.2.2.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Observability
        hosts: observability
        become: true
        roles:
          - role: sentenz.observability.prometheus.node_exporter
      ```

#### 1.2.3. Alertmanager

##### 1.2.3.1. Details

1. Compoments and Features

    - [Alertmanager](https://github.com/prometheus/alertmanager)
      > The Alertmanager handles alerts sent by client applications such as the Prometheus server.

      > [!NOTE]
      > Available as [Ansible Role](roles/prometheus/alertmanager/tasks/main.yml) in the Collection.

    - [Alertmanager](https://hub.docker.com/r/prom/alertmanager) Docker Hub
      > The official Alertmanager docker container.

##### 1.2.3.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Observability
        hosts: observability
        become: true
        roles:
          - role: sentenz.observability.prometheus.alertmanager
      ```
