gem 'rspec'
require('rspec')
require('rspec/core/rake_task')
#require('rcov_report')

gem 'ZenTest'
require('autotest')
require('autotest/rspec2')

namespace :spec do
  desc "Run specs"
  RSpec::Core::RakeTask.new(:html) do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.rspec_opts = ['--format', 'html:doc/spec/index.html']
    t.fail_on_error = true
    if RUBY_VERSION < "1.9.0"
      t.rcov = true
      t.rcov_opts = ['--options', "spec/spec.opts"]
    end
  end

  desc "Run specs and output to console"
  RSpec::Core::RakeTask.new(:console) do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.fail_on_error = true
    if RUBY_VERSION < "1.9.0"
      t.rcov = true
      t.rcov_opts = IO.readlines("#{ENV['PWD']}/spec/rcov.opts").map { |line| line.chomp.split(' ') }.flatten
    end
  end
end
