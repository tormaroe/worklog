require 'date'
require 'yaml/store'

$ACTIVE_FILE = 'hours.log'

class ToDo
  attr_reader :db, :end
  def initialize dbFile
    @dbFile = dbFile
    @log_file = "#{dbFile}.log"
    @db = YAML::Store.new @dbFile
  end
  def prompt
    render
    get_command.execute
  end
  def get_command
    command = gets.chomp
    case command
    when /^(quit)|q$/
      @end = true
    when /^add /
      return AddTodoCommand.new(command[4..-1], self)
    when /^done /
      return DoneCommand.new(command[5..-1], self)
    when /^move /
      return MoveCommand.new(command[5..-1], self)
    when /^delete /
      return DeleteCommand.new(command[7..-1], self)
    when /^new-day/
      return NewDayCommand.new(self)
    end
    return NilCommand.new
  end
  def section_desc s
    {"A" => "-- [A] TODAY       --",
     "B" => "-- [B] TOMORROW    --",
     "C" => "-- [C] IN TWO DAYS --",
     "D" => "-- [D] FUTURE      --"}[s]
  end
  def render
    puts '----------------------------------------------'
    todo_index = 1
    @db.transaction(true) do
      @db.roots.each do |section|
        puts section_desc(section)
        @db[section].each do |t|
          puts "   [#{todo_index}] #{t}"
          todo_index += 1
        end
        puts
      end
    end
    puts "----------------------------------------------"
    puts " add Z text    | done #        | move # Z"
    puts " new-day       | delete #      | quit"
    puts "----------------------------------------------"
    print ">> "
  end
  def log txt
    File.open(@log_file, 'a') {|f| f.puts "#{DateTime.now}: #{txt}" }
  end

  class NilCommand
    def execute
    end
  end

  class AddTodoCommand
    def initialize arg, todo
      @section = arg[0].upcase
      @text = arg[2..-1]
      @todo = todo
    end
    def execute
      @todo.db.transaction do
        execute_existing_transaction
        @todo.log "Added \"#{@text}\" to #{@section}"
      end
    end
    def execute_existing_transaction
      @todo.db[@section] ||= Array.new
      @todo.db[@section] << @text
    end
  end

  class DoneCommand
    def initialize arg, todo
      @done_index = arg.to_i
      @todo = todo
    end
    def execute
      todo_index = 0
      @todo.db.transaction do
        @todo.db.roots.each do |section|
          @todo.db[section].each_with_index do |t,i|
            todo_index += 1
            if todo_index == @done_index
              @todo.db[section].delete_at i
              puts "* Removing #{t}"
              @todo.log "** Completed \"#{t}\""
            end
          end
          puts
        end
      end
    end
  end


  class DeleteCommand
    def initialize arg, todo
      @done_index = arg.to_i
      @todo = todo
    end
    def execute
      todo_index = 0
      @todo.db.transaction do
        @todo.db.roots.each do |section|
          @todo.db[section].each_with_index do |t,i|
            todo_index += 1
            if todo_index == @done_index
              @todo.db[section].delete_at i
              puts "* Deleting #{t}"
              @todo.log "Deleted \"#{t}\""
            end
          end
          puts
        end
      end
    end
  end

  class MoveCommand
    def initialize arg, todo
      p arg
      tokens = /^(\d+) ([ABCDabcd])$/.match(arg)
      @from_index = tokens[1].to_i
      @to_section = tokens[2]
      @todo = todo
    end
    def execute
      todo_index = 0
      @todo.db.transaction do
        @todo.db.roots.each do |section|
          @todo.db[section].each_with_index do |t,i|
            todo_index += 1
            if todo_index == @from_index
              @todo.db[section].delete_at i
              AddTodoCommand.new("#{@to_section} #{t}", @todo).execute_existing_transaction
              puts "* Moved \"#{t}\" from #{section} to #{@to_section}"
              @todo.log "* Moved \"#{t}\" from #{section} to #{@to_section}"
            end
          end
        end
      end
    end
  end

  class NewDayCommand
    def initialize todo
      @todo = todo
    end
    def execute
      @todo.db.transaction do
        @todo.db["A"].push(*@todo.db["B"])
        @todo.db["B"] = []

        @todo.db["B"].push(*@todo.db["C"])
        @todo.db["C"] = []

        puts "Moved tasks up one level"
        puts "REVIEW FUTURE section!!!"

        @todo.log "Advanced to a new day!"
      end
    end
  end
end


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
  entry.date = Prompt.date 'Today [default] or another day (YYYY-MM-DD) : '
  entry.time_from = Prompt.time 'From HH:mm : '
  entry.time_to = Prompt.time   '  To HH:mm : '
  entry.comment = Prompt.required 'Comment : '
  return entry
end

module Prompt
  def self.yes_or_no? msg
    ['Y','y'].include? with_validation("#{msg} [Yes/No]? " , /^[Y|N|y|n]/)[0]
  end

  def self.required msg
    with_validation(msg, /^.+$/)[0]
  end

  def self.date msg
    input = with_validation msg, /^(?:(\d{4}).?(\d{2}).?(\d{2}))?$/
      return Date.today if input[0] == ''
    return "#{input[1]}-#{input[2]}-#{input[3]}"
  end

  def self.time msg
    input = with_validation msg, /^(\d\d).?(\d\d)$/
      return "#{input[1]}:#{input[2]}"
  end

  def self.with_validation msg, format
    while true
      print msg
      input = format.match(gets.chomp)
      return input if input
      puts "** ERROR - INVALID FORMAT - PLEASE TRY AGAIN!"
    end
  end
end

def verify_active_file
  exists = File.exist? $ACTIVE_FILE
  puts "Work log is empty!" unless exists
  return exists
end


