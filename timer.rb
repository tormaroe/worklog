require 'date'

=begin
    =======================
    ==== CONFIGURATION ====
    ======================= 
=end

$ACTIVE_FILE = 'timer.log'

=begin
    =======================
    ==== COMMAND STUFF ====
    ======================= 
=end

class Command
  attr_accessor :description, :proc
  def initialize description, &block
    @description = description
    @proc = Proc.new block
  end
  def call
    @proc.call
  end
  def describe key
    print key.upcase.rjust(12).ljust(16)
    puts @description
  end
end

## ADD NEW COMMAND HERE!
$commands = {
  "add" => Command.new("Adds an entry to the work log") { save prompt_new_entry },
  "tail" => Command.new("Display the current work log") { tail },
  "clear" => Command.new("Clear the current work log") { clear },
  "archive" => Command.new("Dump current work log to archive file") { archive },
}

def handle_command c
  c = c.downcase
  if $commands.has_key? c
    $commands[c].call
  else
    puts "\nUsage: timer.rb COMMAND\n\nAvailable commands:\n\n"
    $commands.sort.each {|key, value| value.describe key }
    puts
  end
end


=begin
    =======================
    ====   WORK LOG    ====
    ======================= 
=end
class Entry
  attr_accessor :date, 
    :time_from, 
    :time_to, 
    :comment

  def to_s
    "#{date}\t#{time_from}\t#{time_to}\t#{comment}\n"
  end
end

def prompt_new_entry
  entry = Entry.new
  
  print 'Today [default] or another day : '
  entry.date = gets.chomp
  entry.date = Date.today if entry.date == ''

  entry.time_from = prompt_valid_time 'From ##:## : '
  entry.time_to = prompt_valid_time   '  To ##:## : '

  print 'Comment : '
  entry.comment = gets.chomp

  return entry
end

def prompt_valid_time msg
  while true
    print msg
    input = /^(\d\d).(\d\d)$/.match(gets.chomp)
    return "#{input[1]}:#{input[2]}" if input
    puts "** ERROR - INVALID FORMAT - PLEASE TRY AGAIN!"
  end
end

=begin
    =======================
    ====  FILE STUFF   ====
    ======================= 
=end
def verify_active_file
  exists = File.exist? $ACTIVE_FILE
  puts "Work log is empty!" unless exists
  return exists
end

def tail
  if verify_active_file
    puts "Printing content of #{$ACTIVE_FILE}:"
    File.readlines($ACTIVE_FILE).each {|line| puts line }
  end
end

def save entry
  File.open($ACTIVE_FILE, 'a') {|f| f.write entry }
end

def clear
  if verify_active_file
    print 'Type FOOBAR to confirm deletion of active file: '
    if gets.chomp == 'FOOBAR'
      File.delete $ACTIVE_FILE 
      puts "File deleted!"
    end
  end
end

def archive
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


=begin
    =======================
    ====   BOOTSTRAP   ====
    ======================= 
=end
puts "~~~ T-MANs SIMPLE WORK LOG TOOL ~~~"
handle_command (ARGV.shift || "")
