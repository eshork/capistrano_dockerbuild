    This content is specific to deployments using docker-compose; if you haven't yet reviewed README.md, you should probably start there.

# docker:compose

This deploy strategy copies a docker-compose.yml file to all the servers you specify, and then runs `docker-compose up` across the whole lot.

This is a very basic deployment strategy; I wouldn't recommend for anything complex, but it will probably work fine for small projects with a single deploy target, or if you just want to make sure all the servers are running the same set of containers and don't mind getting your hands dirty if/when it randomly breaks in the middle.

There is no blue/green, rolling update, auto rollback on failure, or anything even close. Have fun!


### Roles:

This gem adds the `docker_compose` role, identifying hosts where the docker_compose_file should be copied and ran.

If the `docker_build` role is defined, it will identify the source of the docker_compose_file

```ruby
# using the `server` command
server 'my.remote.server', roles: %w{docker_compose}
server 'my_other.remote.server', roles: %w{docker_compose}

# or using the `role` command
role :docker_compose,  %w{localhost} # places localhost within the docker_compose role

# The docker_build role is used to identify the source of the docker_compose_file
role :docker_build,  %w{my.build.server} # copies the docker_compose_file from my.build.server and distributes it to all docker_compose roles

# It is also acceptable to have no docker_build role defined
# role :docker_build,  %w{commented.out} # no docker_build role (commented out), so the docker_compose_file is copied from local workstation project directory
```


### Configurable options:

```ruby
set :docker_compose_project -> { fetch(:application) }        # (required) name of the docker-compose project
set :docker_compose_file, 'docker-compose.yml'                # name of compose file to use for deploy
set :docker_compose_cmd, 'docker-compose'                     # name/path to `docker-compose` command on host
set :docker_compose_opts, nil                                 # general args for `docker-compose`; default is none; (ex: '--project-name myproject --tls')
set :docker_compose_up_opts, '-d --no-build --remove-orphans' # args for `docker-compose up` command; these are the defaults
set :docker_compose_stop_opts, nil                            # args for `docker-compose stop` command; default is none; (ex: '--timeout 20')
set :docker_compose_path -> { deploy_path }                   # path on remote hosts for docker-compose deployments
set :dockercompose_deployhook, true                           # set false to skip default deploy hook; default is true
```
