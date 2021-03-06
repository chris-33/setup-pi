# The Gateway container

The gateway is responsible for receiving incoming HTTP requests from the host network and proxying them to the appropriate service containers by means of domain-based routing. It evaluates the HTTP host header for this. As such, it offers a similar functionality as Apache's virtual hosts. However, using Apache would require all virtual hosts to be hosted in the same container, whereas this approach allows for the servers to be in individual containers, be agnostic of the fact that they are being proxied, and the proxy to be its own container, thereby improving separation of concerns.

The heavy lifting is done by the [Redbird](https://github.com/OptimalBits/redbird) framework, the gateway.js script is really just a thin wrapper that registers the site definitions. HTTPS is also supported, including automatic certificate generation and renewal using Let's Encrypt.

## Base configuration

Base configuration is read from `/etc/redbird/redbird.conf` in JSON format and directly passed into the `redbird` constructor function. See [the Redbird documentation](https://github.com/OptimalBits/redbird) for details on individual settings.

## Configuration of new services

New services can be added by placing a site file in /etc/redbird/sites.d. This must be in JSON format and contain at least a `domain` and `target` attribute. Requests whose host header match the `domain` attribute will be routed to the `target`. Optionally, an `options` attribute can be specified. For a discussion of valid options, refer to [the Redbird documentation](https://github.com/OptimalBits/redbird).

An example configuration could be
```json
{
	"domain": "example.com",
	"target": "http://container-name",
	"options": {
		"ssl": {
			"letsencrypt": {
				"email": "me@gmail.com",
				"production": true
			}
		}
	}
}
```

In this example, Redbird's ability to automatically generate SSL/TLS certificates through Let's Encrypt is enabled. **While still in the development phase of setting up a new service, especially when recreating it a lot of times, make sure to set `production` to false, or you may get banned from Let's Encrypt.**
