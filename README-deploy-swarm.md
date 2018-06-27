    This content is specific to deployments using Docker Swarm; if you haven't yet reviewed README.md, you should probably start there.

# docker:swarm




### Configurable options:

```ruby
set :docker_stack_name -> { fetch(:application) }                # (required) name of the docker swarm stack
set :docker_compose_file, 'docker-compose.yml'                   # name of compose file to use for stack deploys
set :docker_swarm_docker_cmd -> { fetch(:docker_cmd, 'docker') } # name/path to `docker-compose` command on docker_swarm hosts
set :docker_stack_deploy_opts, '--prune'                         # args for `docker stack deploy` command; this is the default
set :docker_compose_path -> { deploy_path }                      # path on remote hosts for docker_compose_file deployments

set :dockerswarm_deployhook, true                                # set false to skip default deploy hook; default is true
```

----

```ruby
set :docker_compose_project -> { fetch(:application) }        # (required) name of the docker-compose project
set :docker_compose_file, 'docker-compose.yml'                # name of compose file to use for deploy
set :docker_compose_cmd, 'docker-compose'                     # name/path to `docker-compose` command on host
set :docker_compose_opts, nil                                 # general args for `docker-compose`; default is none; (ex: '--project-name myproject --tls')
set :docker_compose_up_opts, '-d --no-build --remove-orphans' # args for `docker-compose up` command; these are the defaults
set :docker_compose_stop_opts, nil                            # args for `docker-compose stop` command; default is none; (ex: '--timeout 20')
set :dockercompose_deployhook, true                           # set false to skip default deploy hook; default is true
```
