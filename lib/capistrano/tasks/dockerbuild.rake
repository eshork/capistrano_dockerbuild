# frozen_string_literal: true

namespace :docker do

  class DockerImage
    def initialize(repo = nil, name = nil, tag = nil)
      @repository = repo.nil? || repo.empty? ? nil : repo
      @name = name.nil? || name.empty? ? nil : name
      @tag = tag.nil? || tag.empty? ? nil : tag
    end

    def to_s
      return nil unless @name
      "#{@repository ? "#{@repository}/" : nil}#{@name}#{@tag ? ":#{@tag}" : nil}"
    end

    def repo
      return @repository
    end

    def name
      return @name
    end

    def tag
      return @tag
    end

    def valid?
      return false if @repository.nil? && @name.nil? && @tag.nil?
      unless @repository.nil?
        return false if (@repository =~ /^([\d\w])*(:)?\d*$/).nil?
      end
      return false if (@name =~ /^([\d\w])*$/).nil?
      unless @tag.nil?
        return false if (@tag =~ /^([\d\w-])*$/).nil?
      end
      return true
    end

    def self.from_str(str)
      return new unless str
      repo_str = repo_from_str(str)
      name_str = name_from_str(str)
      tag_str = tag_from_str(str)
      return new repo_str, name_str, tag_str
    end

    def self.repo_from_str(str)
      last_slash = str.rindex('/')
      return nil unless last_slash
      return str[0...last_slash]
    end

    def self.name_from_str(str)
      # remove any repo bits
      repo_str = repo_from_str(str)
      str = str.sub("#{repo_str}/", '') if repo_str
      # remove any tag bits
      str.split(':')[0]
    end

    def self.tag_from_str(str)
      # remove any repo bits
      repo_str = repo_from_str(str)
      str = str.sub("#{repo_str}/", '') if repo_str
      # remove any name bits
      str_split = str.split(':')
      return str_split.size > 1 ? str_split[1] : nil
    end
  end

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

  def docker_build_custom_tag
    return nil unless fetch(:docker_build_custom_tag, nil)
    return "#{docker_build_image}:#{fetch(:docker_build_custom_tag)}"
  end

  def docker_build_image_latest_tag?
    return fetch(:docker_build_image_latest_tag?, true)
  end

  def docker_build_image_latest_tag
    return fetch(:docker_build_image_latest_tag) ||
           set(:docker_build_image_latest_tag, "#{docker_build_image}:latest")
  end

  def docker_build_image_release_tag?
    return fetch(:docker_build_image_release_tag?, true)
  end

  def docker_build_image_release_tag
    return fetch(:docker_build_image_release_tag) ||
           set(:docker_build_image_release_tag, "#{docker_build_image}:release-#{release_timestamp}")
  end

  def docker_build_image_revision_tag?
    return fetch(:docker_build_image_revision_tag?, true)
  end

  def docker_build_image_revision_tag
    return nil unless fetch(:current_revision)
    return fetch(:docker_build_image_revision_tag) ||
           set(:docker_build_image_revision_tag, "#{docker_build_image}:REVISION-#{fetch(:current_revision)}")
  end

  def docker_build_image_shortrev_tag?
    return fetch(:docker_build_image_shortrev_tag?, true)
  end

  def docker_build_image_shortrev_tag
    return nil unless fetch(:current_revision)
    return fetch(:docker_build_image_shortrev_tag) ||
           set(:docker_build_image_shortrev_tag, "#{docker_build_image}:rev-#{fetch(:current_revision)[0..6]}")
  end

  def docker_build_image_tags
    tags = []
    tags << docker_build_custom_tag if docker_build_custom_tag
    tags << docker_build_image_release_tag if docker_build_image_release_tag?
    tags << docker_build_image_revision_tag if docker_build_image_revision_tag?
    tags << docker_build_image_shortrev_tag if docker_build_image_shortrev_tag?
    tags << docker_build_image_latest_tag if docker_build_image_latest_tag?
    return tags.uniq.compact
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

  def docker_build_promote_image
    promote_image_tag = fetch(:docker_build_promote_image, nil)
    image_name = DockerImage.from_str(promote_image_tag)
    image_name = DockerImage.new(image_name.repo ? image_name.repo : docker_repo_url,
                                 image_name.name ? image_name.name : docker_build_image,
                                 image_name.tag ? image_name.tag : docker_build_tag)
    promote_tag = image_name.to_s
    return promote_tag
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

  task :local_build_deps => [:local_build_warning, :set_current_revision]

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

  task :remote_build_deps => [:check_docker_build_role, :check_docker_build_root, :set_current_revision]

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


  task :set_current_revision => 'deploy:set_current_revision'

  task :get_docker_build_image_id => :set_current_revision do
    if roles(:docker_build).empty?
      run_locally do
        docker_build_image_tags.each do |image_tag|
          docker_build_image_id = capture docker_cmd, :image, :ls, '-q', image_tag
          unless docker_build_image_id.empty?
            set(:docker_build_image_id, docker_build_image_id)
            break
          end
        end
      end
    else
      on roles(:docker_build).first do # |buildremote|
        docker_build_image_tags.each do |image_tag|
          docker_build_image_id = capture docker_cmd, :image, :ls, '-q', image_tag
          unless docker_build_image_id.empty?
            set(:docker_build_image_id, docker_build_image_id)
            break
          end
        end
      end
    end



    unless fetch(:docker_build_image_id)
      fatal 'unable to discern image id'
      raise 'missing image id'
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

  task :push_local => :get_docker_build_image_id do
    run_locally do
      unless docker_repo_url
        warn ':docker_repo_url not defined! No push destination'
        next
      end
      docker_build_image_tags.each do |local_tag|
        repo_tag = docker_repo_tag(local_tag)
        next unless repo_tag
        run_locally do
          execute docker_cmd, :tag,
                  fetch(:docker_build_image_id),
                  repo_tag
          execute docker_cmd, :push,
                  repo_tag
        end
      end
    end
  end

  task :push_remote => [:check_docker_build_role, :get_docker_build_image_id] do
    on roles(:docker_build).first do # |buildremote|
      unless docker_repo_url
        warn ':docker_repo_url not defined! No push destination'
        next
      end
      docker_build_image_tags.each do |local_tag|
        repo_tag = docker_repo_tag(local_tag)
        next unless repo_tag
        on roles(:docker_build).first do # |buildremote|
          execute docker_cmd, :tag,
                  fetch(:docker_build_image_id),
                  repo_tag
          execute docker_cmd, :push,
                  repo_tag
        end
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


  desc 'Promote an existing docker image (pull and retag)'
  task :promote do
    if roles(:docker_build).empty?
      invoke 'docker:promote_local'
    else
      invoke 'docker:promote_remote'
    end
  end

  task :check_docker_build_promote_image do
    unless fetch :docker_build_promote_image
      run_locally do
        fatal ':docker_build_promote_image setting is required for promote task'
        raise 'missing :docker_build_promote_image'
      end
    end
    unless DockerImage.from_str(docker_build_promote_image).valid?
      run_locally do
        fatal ":docker_build_promote_image setting is not valid: '#{fetch(:docker_build_promote_image)}' => '#{docker_build_promote_image}'"
        raise 'invalid :docker_build_promote_image'
      end
    end
  end

  task :promote_local => :check_docker_build_promote_image do
    run_locally do
      source_tag = docker_build_promote_image
      info "Promoting image: #{source_tag}"
      execute docker_cmd, :pull, source_tag

      docker_repo_tags.each do |repo_tag|
        next if repo_tag == source_tag
        info "Promoted to: #{repo_tag}"
        execute docker_cmd, :tag,
                source_tag,
                repo_tag
        execute docker_cmd, :push,
                repo_tag
      end

    end
  end

  task :promote_remote => :check_docker_build_promote_image do
    on roles(:docker_build).first do # |buildremote|
      source_tag = docker_build_promote_image
      info "Promoting image: #{source_tag}"
      execute docker_cmd, :pull, source_tag

      docker_repo_tags.each do |repo_tag|
        next if repo_tag == source_tag
        info "Promoted to: #{repo_tag}"
        execute docker_cmd, :tag,
                source_tag,
                repo_tag
        execute docker_cmd, :push,
                repo_tag
      end

    end
  end


  desc '(alias for docker:build_push)'
  task :deploy => :build_push


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
