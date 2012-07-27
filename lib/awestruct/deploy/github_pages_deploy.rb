require 'awestruct/deployers'
require 'git'

module Awestruct
  module Deploy

    class GitHubPagesDeploy
      def initialize( site_config, deploy_config )
        @site_path = site_config.output_dir
        @branch    = deploy_config[ 'branch' ] || 'gh-pages'
      end

      def run
        git.status.changed.empty? ? publish_site : message_for(:existing_changes)
      end

      private
      def git
        @git ||= ::Git.open('.')
      end

      def publish_site
        current_branch = git.current_branch
        git.branch( @branch ).checkout
        add_and_commit_site @site_path
        git.push( 'origin', @branch )
        git.checkout( current_branch )
      end

      def add_and_commit_site( path )
        git.with_working( path ) do
          git.add(".")
          begin
            git.commit("Published #{@branch} to GitHub pages.")
          rescue ::Git::GitExecuteError => e
            $stderr.puts "Can't commit. #{e}."
          end
        end
        git.reset_hard
      end

      def message_for( key )
        $stderr.puts case key
        when :existing_changes 
          "You have uncommitted changes in the working branch. Please commit or stash them."
        else 
          "An error occured."
        end
      end
    end
  end
end

Awestruct::Deployers.instance[ :github_pages ] = Awestruct::Deploy::GitHubPagesDeploy
