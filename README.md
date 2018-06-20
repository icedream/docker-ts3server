# TeamSpeak3 Docker image

TeamSpeak3 server as a Docker image!

## Usage

This container has been preconfigured to store and access configuration and
logs from a volume folder at `/data`. The respective parameters are defined as
part of the entrypoint. When defining **custom parameters**, you should expand
on these parameters by specifying them as __command__, not as __entrypoint__.

You will have to agree to the TeamSpeak3 server license by either setting the
environment variable `TS3SERVER_LICENSE` to `accept` (you can also set it
to `view` to view it) or by passing the command line parameter `license_accepted=1`.

### Directly

You can run this image directly like this:

```sh
docker run --name teamspeak3-server \
  -e TS3SERVER_LICENSE=accept \
  -v /path/to/ts3/data:/data:Z
  icedream/ts3server
```

### docker-compose

Here is an example configuration for `docker-compose`:

```yaml
version: "3.3"

volumes:
  ts3server_data:

services:
  ts3server:
    image: icedream/ts3server

    # You can also build the image directly from GitHub like this:
    #build:
    #  context: https://github.com/icedream/docker-ts3server.git
    #
    #  # Uncomment to use Alpine image variant. Builds Debian image variant
    #  # otherwise.
    #  #dockerfile: alpine.Dockerfile
    #  
    #  # You can set any of the build arguments
    #  args:
    #    TS3SERVER_VERSION: 3.1.2
    #    TS3SERVER_SHA384: <sha384 sum of the version you want to build for>
    #    TS3SERVER_URL: <direct URL to a mirror of the TeamSpeak3 version>
    #    # ...

    volumes:
      - ts3server_data:/data

    ports:
      - "9987-9999:9987-9999/udp" # voice/virtual server UDP ports
      - "10011:10011" # query TCP port
      - "30011:30011" # file transfer TCP port
    
    environment:
      TZ: Europe/Berlin # set timezone
      TS3SERVER_LICENSE: accept # accept server license

    # Define custom parameters for the server here. Especially useful for
    # automatic first-time setup.
    #command:
    #  - dbplugin=ts3db_mariadb
    #  - dbpluginparameter=ts3db_mariadb.ini
    #  - dbsqlcreatepath=create_mysql/
```

**Note:** If you mount a host path as data volume, make sure you created the
folder beforehand and set up permissions in a way to allow for a user with the
ID `9999` to read from and write to the directory. You can follow one of these
solutions:

1. `chown 9999:9999 /path/to/ts3/data`
2. `chmod 777 /path/to/ts3/data`

## MySQL/MariaDB

To make TeamSpeak3 store its SQL data to a MySQL or MariaDB instance, you need
to pass the following parameters to the container:

- `dbplugin=ts3db_mariadb` (don't change this)
- `dbpluginparameter=ts3db_mariadb.ini` (you can use any file name, this is where the MySQL/MariaDB settings will be read from relative to the data directory)
- `dbsqlcreatepath=create_mariadb/` (don't change this, this is relative to the TeamSpeak3 installation's SQL folder which is located at `/opt/teamspeak3/sql/`)

## Activating server license

Server license keys should be pasted as-is in the `/data` volume folder.

Alternatively, you can change the path from which to read the license key using
the parameter below:

- `licensepath=/path/to/license.key`

Useful for providing the license key as configuration file for Docker Swarm.
