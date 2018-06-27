# frozen_string_literal: true

# add the build->push process onto the end of the deploy:published stack
after 'deploy:published', 'docker:capdeploy_hook'

# push the no_release auto-cull to the very front of the task stack
before 'deploy:starting', 'docker:trim_release_roles'
