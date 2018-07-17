# frozen_string_literal: true

require 'tempfile'

namespace :docker do
  namespace :compose do

    def docker_compose_cmd
      fetch(:docker_compose_cmd, 'docker-compose')
    end

    def docker_compose_project
      (fetch(:docker_compose_project) { fetch(:application) }) || raise('unable to discern docker_compose_project name; specify :application or :docker_compose_project')
    end

    def docker_compose_opts
      fetch(:docker_compose_opts, nil)
    end

    def docker_compose_up_opts
      fetch(:docker_compose_up_opts, '-d --no-build --remove-orphans')
    end

    def docker_compose_stop_opts
      fetch(:docker_compose_stop_opts, nil)
    end

    def docker_compose_down_opts
      fetch(:docker_compose_down_opts, '-v --remove-orphans')
    end

    # Relative path to the docker-compose.yml for deployments
    def docker_compose_file
      fetch(:docker_compose_file, 'docker-compose.yml')
    end

    # Path for docker-compose remote deployments
    def docker_compose_path
      fetch(:docker_compose_path) { build_path }
    end


    task :check_docker_compose_root do
      on roles(:docker_compose) do |remote|
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
      if roles(:docker_compose).empty?
        invoke 'docker:compose:upload_local'
      else
        invoke 'docker:compose:upload_remote'
      end
    end

    # copies a new docker-compose.yml file up to each docker_compose host
    task :upload_local do
      run_locally do
        info 'Nothing to do here, docker-compose will run locally...'
      end
    end

    # copies a new docker-compose.yml file up to each docker_compose host
    task :upload_remote => :check_docker_compose_root do
      tmp_file = Tempfile.new('upload_remote')
      tmp_file_path = tmp_file.path
      tmp_file.close(false)
      begin
        docker_build_role = roles(:docker_build).first
        upload_roles = roles(:docker_compose) - [docker_build_role]
        unless upload_roles.empty?
          if docker_build_role
            on docker_build_role do |build_remote|
              info "fetching #{build_remote}:#{docker_compose_path.join(docker_compose_file)}"
              download! docker_compose_path.join(docker_compose_file), tmp_file_path
            end
          else
            invoke 'docker:compose:local_source_warning'
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


    desc 'list current services state'
    task :ps do
      if roles(:docker_compose).empty?
        invoke 'docker:compose:ps_local'
      else
        invoke 'docker:compose:ps_remote'
      end
    end

    task :ps_local do
      current_build_dir = pwd
      run_locally do
        info "Current Working Directory: #{current_build_dir}"
        execute docker_compose_cmd,
                "--file=#{docker_compose_file}",
                "--project-name=#{docker_compose_project}",
                docker_compose_opts,
                :ps
      end
    end

    task :ps_remote do
      on roles(:docker_compose) do |buildremote|
        info "ON HOST #{buildremote}"
        within build_path do
          execute docker_compose_cmd,
                  "--file=#{docker_compose_file}",
                  "--project-name=#{docker_compose_project}",
                  docker_compose_opts,
                  :ps
        end
      end
    end


    desc 'starts/updates services'
    task :up do
      if roles(:docker_compose).empty?
        invoke 'docker:compose:up_local'
      else
        invoke 'docker:compose:up_remote'
      end
    end

    task :up_local do
      current_build_dir = pwd
      run_locally do
        info "Current Working Directory: #{current_build_dir}"
        execute docker_compose_cmd,
                "--file=#{docker_compose_file}",
                "--project-name=#{docker_compose_project}",
                docker_compose_opts,
                :up,
                docker_compose_up_opts
      end
    end

    task :up_remote do
      on roles(:docker_compose) do |buildremote|
        info "ON HOST #{buildremote}"
        within build_path do
          execute docker_compose_cmd,
                  "--file=#{docker_compose_file}",
                  "--project-name=#{docker_compose_project}",
                  docker_compose_opts,
                  :up, '-d',
                  docker_compose_up_opts
        end
      end
    end


    desc 'stops services but leaves them created'
    task :stop do
      if roles(:docker_compose).empty?
        invoke 'docker:compose:stop_local'
      else
        invoke 'docker:compose:stop_remote'
      end
    end

    task :stop_local do
      current_build_dir = pwd
      run_locally do
        info "Current Working Directory: #{current_build_dir}"
        execute docker_compose_cmd,
                "--file=#{docker_compose_file}",
                "--project-name=#{docker_compose_project}",
                docker_compose_opts,
                :stop,
                docker_compose_stop_opts
      end
    end

    task :stop_remote do
      on roles(:docker_compose) do |buildremote|
        info "ON HOST #{buildremote}"
        within build_path do
          execute docker_compose_cmd,
                  "--file=#{docker_compose_file}",
                  "--project-name=#{docker_compose_project}",
                  docker_compose_opts,
                  :stop,
                  docker_compose_stop_opts
        end
      end
    end


    desc 'stop and clean up all services'
    task :down do
      if roles(:docker_compose).empty?
        invoke 'docker:compose:down_local'
      else
        invoke 'docker:compose:down_remote'
      end
    end

    task :down_local do
      current_build_dir = pwd
      run_locally do
        info "Current Working Directory: #{current_build_dir}"
        execute docker_compose_cmd,
                "--file=#{docker_compose_file}",
                "--project-name=#{docker_compose_project}",
                docker_compose_opts,
                :down,
                docker_compose_down_opts
      end
    end

    task :down_remote do
      on roles(:docker_compose) do |buildremote|
        info "ON HOST #{buildremote}"
        within build_path do
          execute docker_compose_cmd,
                  "--file=#{docker_compose_file}",
                  "--project-name=#{docker_compose_project}",
                  docker_compose_opts,
                  :down,
                  docker_compose_down_opts
        end
      end
    end


    desc 'Update docker-compose on all hosts and re-up'
    task :update do
      invoke 'docker:compose:upload'
      invoke 'docker:compose:up'
    end

    desc '(alias for docker:compose:update)'
    task :deploy => :update

    # Default `cap env deploy` flow hook
    task :capdeploy_hook do
      if fetch(:dockercompose_deployhook, true)
        invoke 'docker:compose:update'
      end
    end

  end # namespace :compose do
end # namespace :docker do
