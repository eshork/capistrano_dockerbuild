# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'capistrano_dockerbuild'
  spec.version       = '1.0.0'
  spec.authors       = ['Eric Shorkey']
  spec.email         = ['eric.shorkey@gmail.com']

  spec.summary       = 'docker build/push plugin for Capistrano'
  spec.description   = 'Build, push, promote, and deploy Docker container images with Capistrano.' \
                       ' Build images locally or from a build server, rebuild or promote images across deployment environments.' \
                       ' Deployments for docker-compose and docker swarm.'
  spec.homepage      = 'https://github.com/eshork/capistrano_dockerbuild'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  # end

  # spec.files = `git ls-files -z`.split("\x0").reject do |f|
  #   f.match(%r{^(test|spec|features)/})
  # end

  spec.files = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '>= 3.11'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 12.0'
  # spec.add_development_dependency 'rspec', '~> 3.0'
end
