# frozen_string_literal: true

module Capistrano
  module DSL
    module Paths

      def build_from
        fetch(:build_from)
      end

      # directory within which the build is to be executed
      # respects relative paths (not starting with /)
      def build_path
        return deploy_path.join(fetch(:current_directory, 'current')) if build_from.nil?
        return Pathname.new(build_from.strip) if build_from.strip[0] == '/'
        return deploy_path.join(fetch(:current_directory, 'current'), build_from)
      end

    end
  end
end
