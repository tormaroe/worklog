require 'date'

$ACTIVE_FILE = 'hours.log'

module WorkLog
  def self.run
    puts '~~~ T-MANs SIMPLE WORK LOG TOOL ~~~'
    handle_command (ARGV.shift || "")
  end
end

class Command
  class << self; attr_reader :all end
  @all = {}
  def self.define key, description, &block
    @all[key.to_s] = Command.new(description, &block) 
  end
  
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

def handle_command c
  c = c.downcase
  if Command.all.has_key? c
    Command.all[c].call
  else
    puts "\nUsage: worklog.rb COMMAND\n\nAvailable commands:\n\n"
    Command.all.sort.each {|key, value| value.describe key }
    puts
  end
end

class Entry
  attr_accessor :date, 
    :time_from, 
    :time_to, 
    :comment

  def to_s
    "#{date}\t#{time_from}\t#{time_to}\t#{duration}\t#{comment}\n"
  end

  def save
    File.open($ACTIVE_FILE, 'a') {|f| f.write self }
  end

  def duration
    from_hour = @time_from[0..1].to_i
    from_min  = @time_from[3..4].to_i
    to___hour = @time_to[0..1].to_i
    to___min  = @time_to[3..4].to_i
    minutes_spent = (to___hour - from_hour) * 60
    minutes_spent += to___min - from_min
    hours_spent = minutes_spent / 60
    minutes_spent -= hours_spent * 60
    "#{hours_spent}h #{minutes_spent}m"
  end
end

def prompt_new_entry
  entry = Entry.new
  
  print 'Today [default] or another day : '
  entry.date = gets.chomp
  entry.date = Date.today if entry.date == ''

  entry.time_from = prompt_valid_time 'From HH:MM : '
  entry.time_to = prompt_valid_time   '  To HH:MM : '

  print 'Comment : '
  entry.comment = gets.chomp

  return entry
end

def prompt_valid_time msg
  while true
    print msg
    input = /^(\d\d).?(\d\d)$/.match(gets.chomp)
    return "#{input[1]}:#{input[2]}" if input
    puts "** ERROR - INVALID FORMAT - PLEASE TRY AGAIN!"
  end
end

def verify_active_file
  exists = File.exist? $ACTIVE_FILE
  puts "Work log is empty!" unless exists
  return exists
end


