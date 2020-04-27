require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rdoc/task'

RDoc::Task.new do |t|
	t.main = 'README.md'
	t.rdoc_files.include 'README.md', 'CODE_OF_CONDUCT.md',
	                     'LICENSE.txt', 'lib/**/*.rb'
	t.options << '--tab-width'
	t.options << '2'
end

Rake::TestTask.new :test do |t|
	t.libs << 'test'
	t.libs << 'lib'
	t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test
