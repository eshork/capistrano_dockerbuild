# frozen_string_literal: true

namespace :docker do

  # Any extra command-line opts you'd like to insert into the `docker build` command
  # Normally has no preset value (fastest option), but a popular full-rebuild-every-time (thorough build) selection is '--pull --no-cache --force-rm'
  def docker_build_opts
    fetch(:docker_build_opts, nil)
  end

  # Relative path to the Dockerfile for image building
  def dockerfile
    fetch(:dockerfile, 'Dockerfile')
  end

  # Docker build source path
  def docker_build_context
    fetch(:docker_build_context, '.')
  end

  def docker_cmd
    fetch(:docker_cmd, 'docker')
  end

  def docker_build_image
    (fetch(:docker_build_image) { fetch(:application) }) || raise('unable to discern docker_build_image name; specify :application or :docker_build_image')
  end

  def docker_build_tag
    fetch(:docker_build_tag, 'latest')
  end

  def docker_build_image_tag
    return fetch(:docker_build_image_tag) ||
           set(:docker_build_image_tag, "#{docker_build_image}:#{docker_build_tag}")
  end

  def docker_build_image_latest_tag
    return fetch(:docker_build_image_latest_tag) ||
           set(:docker_build_image_latest_tag, "#{docker_build_image}:latest")
  end

  def docker_build_image_release_tag
    return fetch(:docker_build_image_release_tag) ||
           set(:docker_build_image_release_tag, "#{docker_build_image}:release-#{release_timestamp}")
  end

  def docker_build_image_revision_tag
    return nil unless fetch(:current_revision)
    return fetch(:docker_build_image_revision_tag) ||
           set(:docker_build_image_revision_tag, "#{docker_build_image}:REVISION-#{fetch(:current_revision)}")
  end

  def docker_build_image_shortrev_tag
    return nil unless fetch(:current_revision)
    return fetch(:docker_build_image_shortrev_tag) ||
           set(:docker_build_image_shortrev_tag, "#{docker_build_image}:rev-#{fetch(:current_revision)[0..6]}")
  end

  def docker_build_image_tags
    [
      docker_build_image_latest_tag,
      docker_build_image_revision_tag,
      docker_build_image_shortrev_tag,
      docker_build_image_release_tag,
      docker_build_image_tag,
    ].uniq.compact
  end

  def docker_build_image_tags_opt
    return docker_build_image_tags.map{|t| "--tag=#{t}"}.join(' ')
  end

  def docker_repo_url
    fetch :docker_repo_url
  end

  def docker_repo_tag(local_tag)
    return nil unless docker_repo_url
    return "#{docker_repo_url}/#{local_tag}"
  end

  def docker_repo_tags
    docker_build_image_tags.map{|t| docker_repo_tag(t)}
  end

  # TODO: remove this!!!!!!!!
  task :debug do
    byebug # rubocop:disable Lint/Debugger
    puts 'pew pew!'
  end

  task :check_docker_build_role do
    if roles(:docker_build).empty?
      run_locally do
        fatal ':docker_build role is required for remote builds'
        raise 'missing :docker_build role'
      end
    end
    unless roles(:docker_build).size == 1
      run_locally do
        fatal 'cannot assign :docker_build role to more than one server'
        raise 'multiple :docker_build role assignments'
      end
    end
  end

  task :check_docker_build_root do
    on roles(:docker_build).first do # |buildremote|
      info "checking build path: #{build_path}"
      execute :test, '-d', build_path # path exists
      info 'checking for Dockerfile...'
      execute :test, '-f', build_path.join(dockerfile) # Dockerfile is present
      info "checking docker_build_context: #{docker_build_context}"
      execute :test, '-d', build_path.join(docker_build_context) # Dockerfile is present
    end
  end

  task :local_build_warning do
    run_locally do
      warn 'Building docker image directly from local workspace... (typically undesirable, skips several sanity checks)'
      warn '>> assign :docker_build role to enable remote builds'
    end
  end


  task :build_decision do
    if roles(:docker_build).empty?
      invoke 'docker:build_local'
    else
      invoke 'docker:build_remote'
    end
  end

  task :local_build_deps => [:local_build_warning]

  task :build_local => :local_build_deps do
    current_build_dir = pwd
    run_locally do
      info "Current Working Directory: #{current_build_dir}"
      execute docker_cmd,
              'build',
              docker_build_opts,
              "--file=#{dockerfile}",
              docker_build_image_tags_opt,
              docker_build_context
    end
  end

  task :remote_build_deps => [:check_docker_build_role, :check_docker_build_root]

  task :build_remote => :remote_build_deps do
    on roles(:docker_build).first do |buildremote|
      info "Building docker image on :docker_build role: #{buildremote}"
      within build_path do
        execute docker_cmd, :ps
        execute docker_cmd,
                'build',
                docker_build_opts,
                "--file=#{dockerfile}",
                docker_build_image_tags_opt,
                docker_build_context
      end
    end
  end

  task :tag do
    if roles(:docker_build).empty?
      invoke 'docker:tag_local'
    else
      invoke 'docker:tag_remote'
    end
  end

  task :tag_local do
    if docker_build_image_release_tag
      run_locally do
        info 'Re-tagging docker images for upstream push...'
        docker_repo_tags.each do |repo_tag|
          execute docker_cmd, :tag,
                  docker_build_image_latest_tag,
                  repo_tag
        end
      end
    end
  end

  task :tag_remote => :check_docker_build_role do
    if docker_build_image_release_tag
      on roles(:docker_build).first do # |buildremote|
        info 'Re-tagging docker images for upstream push...'
        docker_repo_tags.each do |repo_tag|
          execute docker_cmd, :tag,
                  docker_build_image_latest_tag,
                  repo_tag
        end
      end
    end
  end

  desc "Push the 'latest' image to the repository"
  task :push do
    if roles(:docker_build).empty?
      invoke 'docker:push_local'
    else
      invoke 'docker:push_remote'
    end
  end

  task :push_local => :tag_local do
    run_locally do
      info 'Pushing docker images upstream...'
      docker_repo_tags.each do |repo_tag|
        execute docker_cmd, :push,
                repo_tag
      end
    end
  end

  task :push_remote => [:check_docker_build_role, :tag_remote] do
    on roles(:docker_build).first do # |buildremote|
      info 'Pushing docker images upstream...'
      docker_repo_tags.each do |repo_tag|
        execute docker_cmd, :push,
                repo_tag
      end
    end
  end

  desc 'Build the docker image'
  task :build do
    invoke 'docker:build_decision'
  end

  desc 'Build and push docker image'
  task :build_push do
    invoke 'docker:build'
    invoke 'docker:push'
  end

  # Default `cap env deploy` flow hook
  task :capdeploy_hook do
    if fetch(:dockerbuild_deployhook, true)
      invoke 'docker:build_push'
    end
  end

  task :trim_release_roles do
    if fetch(:dockerbuild_trim_release_roles, true)
      docker_build_server = [roles(:docker_build).first]
      (release_roles(:all) - docker_build_server).each do |server|
        server.set :no_release, true
      end
    end
  end

end # namespace :docker do
