# Ansible Collection for Reverse Proxy

- [1. Roles](#1-roles)
  - [1.1. Traefik](#11-traefik)
    - [1.1.1. Details](#111-details)
    - [1.1.2. Role](#112-role)

## 1. Roles

### 1.1. Traefik

Traefik is a modern HTTP reverse proxy and ingress controller for Cloud Native Edge Router and Application.

#### 1.1.1. Details

1. Compoments and Features

    - [Traefik](https://github.com/traefik/traefik)
      > Traefik is a modern HTTP reverse proxy and load balancer for Cloud Native Application.

      > [!NOTE]
      > Available as [Ansible Role](roles/traefik/tasks/main.yml) in the Collection.

    - [Traefik](https://hub.docker.com/_/traefik) Docker Hub
      > Discover official Docker images from Traefik Labs.

#### 1.1.2. Role

1. Concepts and Techniques

    - [TLS Challenge](https://doc.traefik.io/traefik/user-guides/docker-compose/acme-tls/)
      > Create a certificate with the Let's Encrypt TLS challenge to use https on a service exposed with Traefik.

    - [HTTP Challenge](https://doc.traefik.io/traefik/user-guides/docker-compose/acme-http/)
      > create a certificate with the Let's Encrypt HTTP challenge to use https on a service exposed with Traefik.

    - [DNS Challenge](https://doc.traefik.io/traefik/user-guides/docker-compose/acme-dns/)
      > Create a certificate with the Let's Encrypt DNS challenge to use https on a service exposed with Traefik.

2. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Observability - Setup Grafana with Reverse Proxy (Traefik)
        hosts: observability
        become: true
        roles:
          - role: sentenz.observability.grafana.grafana
          - role: sentenz.reverse_proxy.traefik
      ```
