task :default do
  puts `ruby lumberjack_test.rb`
  raise "tests failed" if $?.exitstatus != 0
end