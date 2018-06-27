# frozen_string_literal: true

# add the build->push process onto the end of the deploy:published stack
after 'deploy:published', 'docker:swarm:capdeploy_hook'
