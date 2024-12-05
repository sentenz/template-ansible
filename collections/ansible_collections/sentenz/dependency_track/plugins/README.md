# `/plugins`

The Collections Plugins Directory can be used to ship various plugins inside an Ansible collection. Each plugin is placed in a folder that is named after the type of plugin it is in. It can also include the `module_utils` and `modules` directory that would contain module utils and modules respectively.

- Project Layout
  > Directory of the majority of plugins currently supported by Ansible. A full list of plugin types can be found at [Working With Plugins](https://docs.ansible.com/ansible-core/2.12/plugins/plugins.html).

    ```markdown
    .
    └── /plugins
        ├── /action
        ├── /become
        ├── /cache
        ├── /callback
        ├── /cliconf
        ├── /connection
        ├── /filter
        ├── /httpapi
        ├── /inventory
        ├── /lookup
        ├── /module_utils
        ├── /modules
        ├── /netconf
        ├── /shell
        ├── /strategy
        ├── /terminal
        ├── /test
        └── /vars
    ```
