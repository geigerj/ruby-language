require "bundler/setup"
require "bundler/gem_tasks"

require "rubocop/rake_task"
RuboCop::RakeTask.new

task :test do
  $LOAD_PATH.unshift "lib", "test"
  Dir.glob("test/**/*_test.rb").each { |file| require_relative file }
end

namespace :test do
  desc "Runs tests with coverage."
  task :coverage do
    require "simplecov"
    SimpleCov.start do
      command_name "google-cloud-language"
      track_files "lib/**/*.rb"
      add_filter "test/"
    end

    Rake::Task["test"].invoke
  end
end

# Acceptance tests
desc "Runs the language acceptance tests."
task :acceptance, :project, :keyfile do |t, args|
  project = args[:project]
  project ||= ENV["GCLOUD_TEST_PROJECT"] || ENV["LANGUAGE_TEST_PROJECT"]
  keyfile = args[:keyfile]
  keyfile ||= ENV["GCLOUD_TEST_KEYFILE"] || ENV["LANGUAGE_TEST_KEYFILE"]
  if project.nil? || keyfile.nil?
    fail "You must provide a project and keyfile. e.g. rake acceptance[test123, /path/to/keyfile.json] or LANGUAGE_TEST_PROJECT=test123 LANGUAGE_TEST_KEYFILE=/path/to/keyfile.json rake acceptance"
  end
  # always overwrite when running tests
  ENV["LANGUAGE_PROJECT"] = project
  ENV["LANGUAGE_KEYFILE"] = keyfile
  ENV["STORAGE_PROJECT"] = project
  ENV["STORAGE_KEYFILE"] = keyfile

  $LOAD_PATH.unshift "lib", "acceptance"
  Dir.glob("acceptance/**/*_test.rb").each { |file| require_relative file }
end

namespace :acceptance do
  desc "Runs acceptance tests with coverage."
  task :coverage, :project, :keyfile do |t, args|
    require "simplecov"
    SimpleCov.start do
      command_name "google-cloud-language"
      track_files "lib/**/*.rb"
      add_filter "acceptance/"
    end

    Rake::Task["acceptance"].invoke
  end

  desc "Runs acceptance cleanup."
  task :cleanup do
  end
end

desc "Start an interactive shell."
task :console do
  require "irb"
  require "irb/completion"
  require "pp"

  $LOAD_PATH.unshift "lib"

  require "google-cloud-language"
  def gcloud; @gcloud ||= Google::Cloud.new; end

  ARGV.clear
  IRB.start
end

require "yard"
require "yard/rake/yardoc_task"
YARD::Rake::YardocTask.new

desc "Generates JSON output from google-cloud-ruby .yardoc"
task :jsondoc => :yard do

  require "rubygems"
  spec = Gem::Specification::load("gcloud.gemspec")

  require "gcloud/jsondoc"
  registry = YARD::Registry.load! ".yardoc"
  generator = Gcloud::Jsondoc::Generator.new registry
  generator.write_to "jsondoc"
  cp ["docs/authentication.md", "docs/toc.json"], "jsondoc", verbose: true
end

task :default => :test
