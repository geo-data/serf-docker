# Serf in a Docker image

This provides:

* The [`geodata/serf`](https://registry.hub.Docker.com/u/geodata/serf/) Docker
  image with [serf](https://www.serfdom.io/) installed.
  
* A distribution agnostic `Makefile` for installing Serf in a Docker image.

The docker and git repository tagging identifies the version of serf installed.

## Using the `geodata/serf` image

The `geodata/serf` Docker image runs serf under
[runit](http://smarden.org/runit/) using the `serf` service.  Assuming runit is
running in the container this means you can use runit commands to control the
service e.g. `sv stop serf` to stop the service and `sv start serf` to start it
again.

The serf service can be configured by adding JSON configuration files to the
`/etc/serf/config.d` directory, either by extending the image or mounting a
volume at that location.  The format for the configuration files is described by
the serf
[`-config-dir`](https://www.serfdom.io/docs/agent/options.html#_config_file)
option.

### Using container linking

Serf agents can be clustered using linked containers.  As an example linking two
agents, open two terminals and in the first run:

    docker run --name node1 geodata/serf

Next, ensure that you create a `./config.d/join.json` file as follows:

```
{
    "start_join": ["node1"]
}
```

This is a serf configuration option that will tell the second agent to join the
first when it starts, using the hostname `node1` to identify the first agent.
Start the second agend in your second terminal:

    docker run --link node1:node1 -v $(pwd)/config.d:/etc/serf/config.d geodata/serf

You should see output from both terminals indicating a successful join.

### Using mDNS multicasting

Serf agents can
[discover](https://www.serfdom.io/docs/agent/options.html#_discover) each other
using multicasting.  To test this, ensure that you create a
`./config.d/discover.json` file as follows:

```
{
    "discover": "my-cluster",
    "interface": "eth0"
}
```

Note that if you followed the example in the previous section, you *must* delete
the `./config.d/join.json` file as otherwise this will be read as part of the
serf configuration (you can have as many JSON files as you want in the
configuration directory..

Next, create as many serf agents as you want in the cluster by repeating this
command (at least twice!).

    docker run -v $(pwd)/config.d:/etc/serf/config.d geodata/serf

## Customising images with the `Makefile`

You can use the `Makefile` in the repository to install serf when building your
own Docker images. This is effectively a kind of mixin for images :).

Firstly clone the repository somewhere accessible to the build process.  From
within the repository root, typing `make install` in the repository will install
the `serf` binary on the system.  The only prerequisite is that the system be 64
bit and have the `make`, `curl` and `funzip` tools available.  `funzip` is
usually bundled as part of the zip package.

There is also a runit target which will install the necessary files for setting
up a runit service.  By default typing in `make runit` will install a service
called `serf`.  The name of the service can be customised by specifying the
`SERVICE` make variable.  E.g. running `make runit -e SERVICE=foobar` will
install a serf agent under the `foobar` runit service.  In order to customise
the service you can add JSON serf configuration files to the
`/etc/${SERVICE}/config.d` directory, as described in the previous section.

## Multiple serf services under runit

Instead of running multiple containers, you may want to run multiple serf
clusters from within a single container under runit.  This can be done by
installing more than one runit service using the `make runit` target as
described in the previous section.  Note, however, that by default both serf
services will attempt to bind to the same ports, and one of them will fail.  To
prevent this the
[`rpc_addr`](https://www.serfdom.io/docs/agent/options.html#rpc_addr)
configuration key must be set in *one* of the service's JSON configuration
files.

Note that the repository package, including the Makefile, is available in the
`geodata/serf` image under `/usr/local/src/serf`: use this to extend the image
with additional services if you need to.
