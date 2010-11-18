require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "mongomatic"
    gem.summary = %Q{Mongomatic is a simple Ruby object mapper for Mongo}
    gem.description = %Q{Mongomatic is a simple Ruby object mapper for Mongo}
    gem.email = "ben.myles@gmail.com"
    gem.homepage = "http://mongomatic.com/"
    gem.authors = ["Ben Myles"]
    gem.files = ["lib/**/*.rb"]
    gem.add_development_dependency "minitest", "~> 2.0"
    gem.add_dependency "bson", "~> 1.1"
    gem.add_dependency "mongo", "~> 1.1"
    gem.add_dependency "activesupport", "~> 3.0.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mongomatic #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
