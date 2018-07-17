# CAVEAT EMPTOR

This is very much a work in progress. It mostly works for my needs, but I'm finding and fixing issues almost every week. Ruthless criticism is currently encouraged. Please submit your bitchiness to: (/dev/null; cc: [github_issue](https://github.com/eshork/capistrano_dockerbuild/issues/new)). 🌮

# capistrano_dockerbuild

Docker image creation, tagging, and repository tasks for Capistrano v3

```sh
cap production docker:deploy # build or promote image and push to repository
```

This plugin also hooks into the default `cap <environment> deploy` flow as a build action. See [Usage](#usage) for more details.



## Installation

Add these lines to your application's Gemfile:

```ruby
gem 'capistrano', '~> 3.11'
gem 'capistrano_dockerbuild', '~> 1.0'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install capistrano_dockerbuild
```

## Usage

#### Require in Capfile:

```ruby
require 'capistrano/dockerbuild'
```

#### Optionally define a docker_build host:

```ruby
role :docker_build,  %w{localhost} # role syntax, making localhost the build agent
# or...
server 'my.build.server', roles: %w{docker_build} # server syntax, declaring a remote server
```

If no `:docker_build` host is defined, the docker image will be built directly from the current working project directory. A maximum of one `:docker_build` host can be defined.

#### Run a deploy:

The plugin automatically hooks the [Capistrano deploy flow](https://capistranorb.com/documentation/getting-started/flow/) after `deploy:published` (ie, you can run `cap <environment> deploy`).

To opt-out of the default deploy hook, add this line to your `config/deploy.rb` or to a specific `config/deploy/<stage>.rb` file:

```ruby
set :dockerbuild_deployhook, false
```

You can also run tasks in isolation. For example:

- `cap development docker:build`
- `cap development docker:push`
- `cap test docker:build_push`

Run `cap -T docker:` for details

*Be aware that `docker:build` tasks ran in isolation currently only generate the `:latest` and `:release-<timestamp>` docker image tags.*

### Configurable options:

```ruby
set :docker_build_image -> { fetch(:application) } # (required) name of the image
set :docker_build_opts, nil                        # additional `docker build` args; default is none; (ex: '--pull --no-cache --force-rm')
set :docker_build_custom_tag, nil                  # custom tag name for this build, if any
set :docker_build_image_latest_tag?, true          # generates a 'latest' tag when true
set :docker_build_image_release_tag?, true         # generates a release tag when true
set :docker_build_image_revision_tag?, true        # generates a scm revision tag when true
set :docker_build_image_shortrev_tag?, true        # generates a short-form scm revision tag when true
set :docker_repo_url, nil                          # name/url of remote docker image repository for push
set :docker_build_context, '.'                     # context passed to `docker build` (from :build_dir)
set :dockerfile, 'Dockerfile'                      # name of Dockerfile to use for build
set :docker_cmd, 'docker'                          # name/path to `docker` command on build host
set :build_dir, '.'                                # directory within source repository to run builds from on remote build hosts
set :docker_build_promote_image, nil               # repository/image:tag to promote instead of building a new image
set :dockerbuild_deployhook, true                  # set false to skip default deploy hook; default is true
set :dockerbuild_trim_release_roles, true          # set false to prevent no_release from being auto-added to all non docker_build servers
```

### Created docker image tags

By default the `docker:build` task creates several image tags on the build host upon completion, all pointing to the same final image. Unless otherwise altered, all created tags are also pushed up to the docker image repository during the `docker:push` task. You may not want your repository (or build host) filled with a ton of tags, so this gem offers a few ways to control that sprawl.

You can selectively turn off remotely pushed tags by setting these to `false`, as desired:

- `:docker_build_image_latest_tag?`
- `:docker_build_image_release_tag?`
- `:docker_build_image_revision_tag?`
- `:docker_build_image_shortrev_tag?`

`:docker_build_custom_tag` is optional; if you don't want a custom tag created, don't set one.


### Deployment to docker-compose, Docker Swarm, Kubernetes, Marathon, etc
The primary goal of this gem is currently to provide tasks for Docker image creation and repository push/transfer. However, some deployment tasks are also included, should you decide to use them. Each deploy strategy needs to be specifically enabled by a separate `requires` statement within your Capfile.

Refer to the specific deployment documentation for details:

- [Deploying with Docker Compose](README-deploy-compose.md)
- [Deploying with Docker Swarm](README-deploy-swarm.md)

## Why?

Because.

There are at least a dozen other Capistrano + Docker gems out there, but none seemed to match my preferred docker philosophy: Docker images should be built once and then promoted up to higher environments as they pass acceptance tests. This gem aims to provide that type of workflow.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eshork/capistrano_dockerbuild


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

