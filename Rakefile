require "bundler/gem_tasks"

bosh_release = "cf-release"
target_bosh_release_path = File.expand_path("../bosh_release", __FILE__)

namespace :bosh do
  namespace :release do
    desc "Import latest #{bosh_release}"
    task :import, :path do |t, args|
      source_bosh_release = File.expand_path(args[:path])
      unless File.directory?(source_bosh_release)
        $stderr.puts "Please pass path to source bosh release"
        exit 1
      end

      sh "rm -rf #{target_bosh_release_path}"

      # required directories to pass bosh_cli validations
      %w[config jobs packages src].each do |dir|
        sh "mkdir -p #{target_bosh_release_path}/#{dir}"
        sh "touch #{target_bosh_release_path}/#{dir}/.gitkeep"
      end

      chdir(target_bosh_release_path) do
        sh "cp -R #{source_bosh_release}/releases #{target_bosh_release_path}"
        sh "cp -R #{source_bosh_release}/.final_builds #{target_bosh_release_path}"
        sh "cp -R #{source_bosh_release}/config/final.yml #{target_bosh_release_path}/config"
      end
    end

    desc "Remove any large temporary tgz from internal bosh_release"
    task :clean do
      chdir(target_bosh_release_path) do
        sh "ls .final_builds/**/*.tgz | xargs rm; true"
        sh "ls releases/**/*.tgz | xargs rm; true"
      end
    end
  end
end

task :release => "bosh:release:clean"