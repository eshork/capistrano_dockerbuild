# frozen_string_literal: true

# Capistrano::DSL::Paths re-open
require_relative 'dsl/paths.rb'

# dockerbuild standard tasks and cap flow hooks
require_relative 'dockerbuild/tasks'
require_relative 'dockerbuild/hooks'
