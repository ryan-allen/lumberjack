require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |s|
	s.pattern = 'spec/*_spec.rb'
end

task :default => :spec
