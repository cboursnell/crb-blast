require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

Rake::TestTask.new do |t|
  t.name = :one
  t.libs << 'test'
  t.test_files = ['test/test_test.rb']
end

Rake::TestTask.new do |t|
  t.name = :two
  t.libs << 'test'
  t.test_files = ['test/test_test2.rb']
end

Rake::TestTask.new do |t|
  t.name = :three
  t.libs << 'test'
  t.test_files = ['test/test_test3.rb']
end

desc "Run tests"
task :default => :test
