# frozen_string_literal: true

require 'tempfile'

namespace :docker do
  namespace :swarm do

    def docker_cmd
      fetch(:docker_swarm_docker_cmd) { fetch(:docker_cmd, 'docker') }
    end

    def docker_stack_name
      (fetch(:docker_stack_name) { fetch(:application) }) || raise('unable to discern docker_stack_name name; specify :application or :docker_stack_name')
    end

    def docker_stack_deploy_opts
      fetch(:docker_stack_deploy_opts, '--prune')
    end

    # Relative path to the docker-compose.yml for deployments
    def docker_compose_file
      fetch(:docker_compose_file, 'docker-compose.yml')
    end

    # Path for docker-compose remote deployments
    def docker_compose_path
      fetch(:docker_compose_path) { build_path }
    end


    task :check_docker_swarm_root do
      on roles(:docker_swarm) do |remote|
        # info "ON HOST #{remote}"
        # info "checking docker_compose_path: #{docker_compose_path}"
        # should really fix this to preserve typical capistrano dir-tree, but meh for now...
        unless test("[ -d #{docker_compose_path} ]")
          warn "docker_compose_path does not exist on host (#{remote}): #{docker_compose_path}"
          warn "creating docker_compose_path on host (#{remote}): #{docker_compose_path}"
          warn 'this can break future `cap stage deploy` execution on build hosts'
          execute :mkdir, '-p', docker_compose_path
        end
      end
    end

    task :local_source_warning do
      run_locally do
        warn 'Using docker-compose files directly from local workspace... (typically undesirable)'
        warn '>> assign :docker_build role to enable remote builds'
      end
    end


    desc 'copies a new docker_compose_file from the docker_build role to each docker_compose role'
    task :upload do
      if roles(:docker_swarm).empty?
        invoke 'docker:swarm:upload_local'
      else
        invoke 'docker:swarm:upload_remote'
      end
    end

    # copies a new docker-compose.yml file up to each docker_swarm host
    task :upload_local do
      run_locally do
        info 'Nothing to do here, docker swarm will run locally...'
      end
    end

    # copies a new docker-compose.yml file up to each docker_swarm host
    task :upload_remote => :check_docker_swarm_root do
      run_locally do
        info 'Copying docker_compose_file to docker_swarm hosts...'
      end
      tmp_file = Tempfile.new('upload_remote')
      tmp_file_path = tmp_file.path
      tmp_file.close(false)
      begin
        docker_build_role = roles(:docker_build).first
        upload_roles = roles(:docker_swarm) - [docker_build_role]
        unless upload_roles.empty?
          if docker_build_role
            on docker_build_role do |build_remote|
              info "fetching #{build_remote}:#{docker_compose_path.join(docker_compose_file)}"
              download! docker_compose_path.join(docker_compose_file), tmp_file_path
            end
          else
            invoke 'docker:swarm:local_source_warning'
            run_locally do
              warn "fetching #{docker_compose_file}"
              download! docker_compose_file, tmp_file_path
            end
          end
          on upload_roles do |upload_role|
            info "uploading to #{upload_role}:#{docker_compose_path.join(docker_compose_file)}"
            upload! tmp_file_path, docker_compose_path.join(docker_compose_file)
          end
        end
      ensure
        File.unlink(tmp_file_path)
      end
    end


    desc 'List the tasks in the stack'
    task :ps do
      if roles(:docker_swarm).empty?
        invoke 'docker:swarm:ps_local'
      else
        invoke 'docker:swarm:ps_remote'
      end
    end

    task :ps_local do
      current_build_dir = pwd
      run_locally do
        info "Current Working Directory: #{current_build_dir}"
        execute docker_cmd,
                :stack,
                :ps,
                docker_stack_name
      end
    end

    task :ps_remote do
      on roles(:docker_swarm) do |buildremote|
        info "ON HOST #{buildremote}"
        within build_path do
          execute docker_cmd,
                  :stack,
                  :ps,
                  docker_stack_name
        end
      end
    end


    desc 'List the services in the stack'
    task :status do
      if roles(:docker_swarm).empty?
        invoke 'docker:swarm:status_local'
      else
        invoke 'docker:swarm:status_remote'
      end
    end

    task :status_local do
      current_build_dir = pwd
      run_locally do
        info "Current Working Directory: #{current_build_dir}"
        execute docker_cmd,
                :stack,
                :services,
                docker_stack_name
      end
    end

    task :status_remote do
      on roles(:docker_swarm) do |buildremote|
        info "ON HOST #{buildremote}"
        within build_path do
          execute docker_cmd,
                  :stack,
                  :services,
                  docker_stack_name
        end
      end
    end



    desc 'starts/updates services'
    task :up do
      if roles(:docker_swarm).empty?
        invoke 'docker:swarm:up_local'
      else
        invoke 'docker:swarm:up_remote'
      end
    end

    task :up_local do
      current_build_dir = pwd
      run_locally do
        info "Current Working Directory: #{current_build_dir}"
        execute docker_cmd,
                :stack,
                :deploy,
                docker_stack_deploy_opts,
                "--compose-file=#{docker_compose_file}",
                docker_stack_name
      end
    end

    task :up_remote do
      on roles(:docker_swarm) do |buildremote|
        info "ON HOST #{buildremote}"
        within build_path do
          execute docker_cmd,
                  :stack,
                  :deploy,
                  docker_stack_deploy_opts,
                  "--compose-file=#{docker_compose_file}",
                  docker_stack_name
        end
      end
    end





    desc 'stop and clean up all services'
    task :down do
      if roles(:docker_swarm).empty?
        invoke 'docker:swarm:down_local'
      else
        invoke 'docker:swarm:down_remote'
      end
    end

    task :down_local do
      current_build_dir = pwd
      run_locally do
        info "Current Working Directory: #{current_build_dir}"
        execute docker_cmd,
                :stack,
                :rm,
                docker_stack_name
      end
    end

    task :down_remote do
      on roles(:docker_swarm) do |buildremote|
        info "ON HOST #{buildremote}"
        within build_path do
          execute docker_cmd,
                  :stack,
                  :rm,
                  docker_stack_name
        end
      end
    end








    desc 'Update all docker_swarm roles'
    task :update do
      invoke 'docker:swarm:upload'
      invoke 'docker:swarm:up'
    end

    desc '(alias for docker:swarm:update)'
    task :deploy => :update

    # Default `cap env deploy` flow hook
    task :capdeploy_hook do
      if fetch(:dockerswarm_deployhook, true)
        invoke 'docker:swarm:update'
      end
    end

  end # namespace :swarm do
end # namespace :docker do
