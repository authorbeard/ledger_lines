require "rake/testtask"

Dir.glob("lib/tasks/*.rake").each { |task_file| load task_file }

Rake::TestTask.new(:test) do |task|
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
  task.warning = false
end

task default: :test
