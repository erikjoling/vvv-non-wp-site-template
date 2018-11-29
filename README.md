# VVV non-wp site template
For when you just need a non-wp site in VVV

- Author: Erik Joling <erik@ejoweb.nl>

# Configuration

```
my-site:
  repo: location_of_custom_provisioner
  hosts:
    - host_1 (primary)
    - host_2
    [...]
```

### Example

```
my-site:
  repo: https://github.com/erikjoling/vvv-non-wp-site-template.git
  hosts:
    - my-site.test
```

