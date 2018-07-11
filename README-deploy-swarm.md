_This content is specific to deployments using Docker Swarm; if you haven't yet reviewed README.md, you should probably start there._

# docker:swarm

This deploy strategy copies a docker-compose.yml file to the docker swarms you specify, and then runs `docker stack up` across the whole lot.

Deploying to a single swarm member should be enough to deploy across the entire swarm, so choosing one deploy host per swarm is probably the best course of action.

### Roles:

This plugin adds the `docker_swarm` role, identifying hosts where the `docker_compose_file` should be copied and ran.

If the `docker_build` role is defined, it will identify the source of the `docker_compose_file`, otherwise the current project directory is the source.

```ruby
# using server syntax
server 'my.swarm.host', roles: %w{docker_swarm}

# or using role syntax
role :docker_swarm,  %w{my.swarm.host}
```



### Configurable options:

```ruby
set :docker_stack_name -> { fetch(:application) }                # (required) name of the docker swarm stack
set :docker_compose_file, 'docker-compose.yml'                   # name of compose file to use for stack deploys
set :docker_swarm_docker_cmd -> { fetch(:docker_cmd, 'docker') } # name/path to `docker-compose` command on docker_swarm hosts
set :docker_stack_deploy_opts, '--prune'                         # args for `docker stack deploy` command; this is the default
set :docker_compose_path -> { deploy_path }                      # path on remote hosts for docker_compose_file deployments

set :dockerswarm_deployhook, true                                # set false to skip default deploy hook; default is true
```
