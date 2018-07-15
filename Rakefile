require 'rubygems'

def gemspec
  file = Dir.glob('*.gemspec').first or raise 'No gemspec found?'
  Gem::Specification.load file
end

GEM_NAME = gemspec.name

def latest_gem
  Dir.glob("#{GEM_NAME}*.gem").sort.last
end

desc "Build the #{GEM_NAME} gem"
task :build do
  sh "gem build #{GEM_NAME}.gemspec"
end

desc "Install the #{GEM_NAME} gem"
task :install, [:version] do |_, args|
  gem = if args.key?(:version)
          "#{GEM_NAME}-#{args[:version]}.gem"
        else
          latest_gem
        end
  raise 'No installable gems found' if gem.nil?
  sh "gem install #{gem}"
end

task :default => [:build, :install]
