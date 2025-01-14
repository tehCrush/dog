<p align="center">
  <img src="../../images/dog-segmented-green.network-200x200.png">
</p>

<h1>dog_on_a_dock</h1>

dog_on_a_dock is a complete dog test/dev environment implemented docker containers via
docker compose
It's meant to provide a way to test changes to dog in a full environment built
from scratch, as well as a way to easily try out dog.

---

## Build/Install

[Docker Compose](https://github.com/docker/compose) is used to create multiple Docker containers.


### Licensed Dependencies

If you are OK with what the License requires, you can use Docker Desktop

- Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Open Source Dependencies

There are multiple ways to install the Open Source versions of Docker/Compose

[MacOS Brew](https://formulae.brew.sh/formula/docker-compose)

[Ubuntu Linux](https://www.theserverside.com/blog/Coffee-Talk-Java-News-Stories-and-Opinions/How-to-install-Docker-and-docker-compose-on-Ubuntu)

[Arch Linux](https://wiki.archlinux.org/title/docker#Docker_Compose)

### Build

This will clone repos, build and start all dog containers:

```bash
git clone https://github.com/tehCrush/dog.git
cd dog

./dog_on_a_dock.sh
```

# Verify

`docker container ls` shoule output something similar to this:

```
CONTAINER ID   IMAGE                 COMMAND                  CREATED          STATUS          PORTS                                                                                                                                                      NAMES
29845d20f19b   dog_dog_agent         "/bin/sh -c '/bin/ba…"   11 minutes ago   Up 11 minutes                                                                                                                                                              dog-agent
0f1857aaa5ab   dog_dog_park          "/docker-entrypoint.…"   30 minutes ago   Up 17 minutes   80/tcp, 3030/tcp                                                                                                                                           dog-park
1aecc0ce60c8   dog_dog_trainer       "/bin/sh -c '/bin/ba…"   30 minutes ago   Up 17 minutes   7070/tcp                                                                                                                                                   dog-trainer
d9ce61f80d84   dog_rabbitmq          "docker-entrypoint.s…"   30 minutes ago   Up 18 minutes   4369/tcp, 5671-5672/tcp, 0.0.0.0:5673->5673/tcp, :::5673->5673/tcp, 15671/tcp, 15691-15692/tcp, 25672/tcp, 0.0.0.0:15672->15672/tcp, :::15672->15672/tcp   rabbitmq
b9d82b3866af   dog_csc               "uvicorn app.main:ap…"   4 days ago       Up 17 minutes   0.0.0.0:8000->8000/tcp, :::8000->8000/tcp                                                                                                                  csc
262fe8491815   jwilder/nginx-proxy   "/app/docker-entrypo…"   4 days ago       Up 17 minutes   0.0.0.0:80->80/tcp, :::80->80/tcp                                                                                                                          dog-nginx-proxy
6b5c3f57b06d   rethinkdb             "rethinkdb --bind all"   2 weeks ago      Up 17 minutes   28015/tcp, 0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 29015/tcp                                                                                            rethinkdb
```

# Use

## dog alias
You must create an alias for localhost called 'dog' for the dog_park gui to work

edit hosts file, add 'dog':
```
127.0.0.1	localhost dog
```

[Windows HOWTO](https://www.nublue.co.uk/guides/edit-hosts-file/)

## Web consoles
Docker is configured to forward the containers' service to the physical hosts'
localhost ports

- dog_park [http://dog:80](http://dog:80)

- rethinkdb [http://localhost:8080](http://localhost:8080)

- rabbitmq [http://localhost:15672](http://localhost:15672)

## Agent Test

- Go to the dog_park GUI: http://dog.
- Create a Service called 'ssh' with TCP port 22.
- Create a Profile called 'dog_test" with a rule allowing 'All' to 'ALLOW' the service 'ssh'.
- Create a Group called 'local_group' (This is the default group in the Docker configuration).
- Ensure the Host 'docker-node-123' is in the Group 'local_group' (The default name of the agent in the Docker configuration).

### Check agent iptables and ipsets

```
docker exec -t -i dog_agent "/usr/sbin/iptables-save"
```

should return something like:

```
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -m comment --comment "local any" -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -j DROP
-A FORWARD -j REJECT --reject-with icmp-port-unreachable
-A OUTPUT -o lo -m state --state RELATED,ESTABLISHED -m comment --comment "local any" -j ACCEPT
-A OUTPUT -p tcp -m tcp --sport 22 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A OUTPUT -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
```

```
docker exec -t -i dog_agent "bash"
> /sbin/ipset save
```

should output something like:

```
create all-active_gv4 hash:net family inet hashsize 1024 maxelem 65536
add all-active_gv4 172.25.0.7
create local_group_gv4 hash:net family inet hashsize 1024 maxelem 65536
add local_group_gv4 172.25.0.7
create all-active_gv6 hash:net family inet6 hashsize 1024 maxelem 65536
create local_group_gv6 hash:net family inet6 hashsize 1024 maxelem 65536
```

## Additional dog_agents
You can attach external dog_agents to the dog_on_on_a_dock.

1. Download latest release in tar.gz format, and extract to /opt/dog/.  Releases are built for Ubuntu 20.x, but will proabaly work in similar Linux distros.
https://github.com/relaypro-open/dog_agent/releases

2. Request a passkey from csc (local CA signed cert).  This passkey can only be used once, and will expire if not used in 5 minutes of being created.

3. Request certificates and host_key with the passkey.

4. Add the hostkey obtained to /etc/dog/config.json

Here is an example script that could be run on a dog_agent instance:
```
#!/bin/bash
passkey=$(curl -s http://dog:8000/csc/register | jq -r .passkey)
certs=$(curl -s -d '{"fqdn": "your_server_name.your_domain.your_tld", "passkey": "'$passkey'"}' http://dog:8000/csc/cert) #fqdn is just a unique naming scheme - you could use any name.
echo $certs | jq -r .server_key > /etc/dog/private/server.key
echo $certs | jq -r .server_crt > /etc/dog/certs/server.crt
echo $certs | jq -r .ca_crt >     /etc/dog/certs/ca.crt
echo $certs | jq -r .hostkey >>   /etc/dog/dog.config #(will need to edit this file to put hostkey into json format)
```
NOTE: NOT FOR USE IN PRODUCTION!  csc is a simple, but insecure way to create CA signed certificates, to allow you to try out dog on some test servers in your environment.  Production systems will require more strict control of the CA itself, and encrypted transfer of the certificates.  

5. Create /etc/dog/config.json, using hotkey from above.
```
{"environment":"*","group":"local_group","hostkey":"$HOSTKEY","location":"*"}
```

6. Create /etc/dog/dog.config:
```
[
    {dog, [
        {version, "local_docker"},
        {enforcing, true},
        {use_ipsets, true}
    ]},
    {kernel,[
     {inet_dist_use_interface,{127,0,0,1}},
      {logger_level, all},
      {logger, [
  
        {handler, default, logger_std_h,
        #{
          level => error,
          formatter => {flatlog,
                          #{max_depth => 3,
                            term_depth => 50,
                            colored => true
        }}}},
        {handler, disk_log_debug, logger_disk_log_h,
          #{config => #{
                file => "/var/log/dog/debug.log",
                type => wrap,
                max_no_files => 5,
                max_no_bytes => 10000000
            },
            level => debug,
            formatter => {flatlog, #{
              map_depth => 3,
              term_depth => 50
            }}
          }
        },

        %%% Disk logger for errors
        {
          handler, disk_log_error, logger_disk_log_h,
          #{config => #{
                file => "/var/log/dog/error.log",
                type => wrap,
                max_no_files => 5,
                max_no_bytes => 10000000
            },
            level => error,
            formatter => {
              flatlog, #{
                map_depth => 3,
                term_depth => 50
              }
            }
          }
        }
    ]

    }]},
    {turtle, [
        {connection_config, [
            #{
                conn_name => default,

                username => "guest",
                password => "guest",
                virtual_host => "dog",
                ssl_options => [
                               {cacertfile, "/etc/dog/certs/ca.crt"},
                               {certfile,   "/etc/dog/certs/server.crt"},
                               {keyfile,    "/etc/dog/private/server.key"},
                               {verify, verify_peer},
                               {server_name_indication, disable},
                               {fail_if_no_peer_cert, true}
                              ],
                deadline => 300000,
                connections => [
                    {main, [
                      {"dog", 5673 } %Whatever hostname your clients will access dog_trainer/rabbitmq
                    ]}
                ]
            }
        ]
    }
    ]},
    {erldocker, [
        {docker_http, <<"http+unix://%2Fvar%2Frun%2Fdocker.sock">>}
    ]},
    {erlexec, [
	   {debug, 0},
	   {verbose, false},
	   {root, true}, %% Allow running child processes as root
	   {args, []},
	   %{alarm, 5},  %% sec deadline for the port program to clean up child pids
	   {user, "root"},
	   {limit_users, ["root"]}
  ]}
].
```

7. Create dog.service: `sudo systemctl --force --full dog.service`

```
[Unit]
Description=dog
After=network-online.target
Requires=network-online.target

[Service]
User=dog
Group=dog
Type=simple

Environment=HOME=/opt/dog
Environment=ERL_EPMD_PORT=4371
ExecStart=/opt/dog/dog start
ExecStop=/opt/dog/dog stop
WorkingDirectory=/opt/dog
Restart=on-failure
RuntimeDirectory=dog

[Install]
WantedBy=multi-user.target
```

8. Start service: `sudo systemctl start dog.service`
