# frozen_string_literal: true

module Capistrano
  module DSL
    module Paths

      def build_dir
        fetch(:build_dir)
      end

      # directory within which the build is to be executed
      # respects relative paths (not starting with /)
      def build_path
        return deploy_path.join(fetch(:current_directory, 'current')) if build_dir.nil?
        return Pathname.new(build_dir.strip) if build_dir.strip[0] == '/'
        return deploy_path.join(fetch(:current_directory, 'current'), build_dir)
      end

    end
  end
end
