require './workloglib.rb'


Command.define :add, "Adds an entry to the current work log" do
  prompt_new_entry.save
end

Command.define :tail, "Display the current work log" do
  if verify_active_file
    puts "Printing content of #{$ACTIVE_FILE}:"
    File.readlines($ACTIVE_FILE).each {|line| puts line }
  end
end

Command.define :clear, "Clear the current work log" do
  if verify_active_file
    print 'Type FOOBAR to confirm deletion of active file: '
    if gets.chomp == 'FOOBAR'
      File.delete $ACTIVE_FILE 
      puts "File deleted!"
    end
  end
end

Command.define :archive, "Dump current work log to archive file" do
  if verify_active_file
    archive_file_name = "archive.#{Date.today}.log"
    File.open(archive_file_name, 'a') do |a|
      File.readlines($ACTIVE_FILE).each {|line| a.write line }
    end
    puts "Work log items moved to #{archive_file_name}"
    File.delete $ACTIVE_FILE 
    puts "Current work log truncated"
  end
end

Command.define :test, "This is just a test" do
  puts "test test test test test"
end

WorkLog.run
