
def main files_to_read
  raise "No files matched the filter" unless files_to_read.length > 0

  puts "Taking snapshot of #{files_to_read.length} files"
  out_file_name = "snapshot.#{Snapshots.new.next_number}.html"
  File.open(out_file_name, 'w') do |out_file|
    builder = SnapshotBuilder.new out_file
    files_to_read.each { |file| builder.add file }
  end
  puts "Created #{out_file_name}"

  update_index 
end

class SnapshotBuilder
  def initialize(out)
    @out = out 
    @out.puts "<!DOCTYPE HTML>"
  end
  def add file
    puts "Scanning #{file}"
    write_item_header file, @out
    File.foreach(file) { |line| @out.puts escape(line) }
    write_item_footer @out
  end
  def write_item_header item, out
    out.puts "<h3>#{item}</h3>"
    out.print "<pre style=\"border:solid 1px #333;padding:8px;margin:5px;\">"
  end
  def write_item_footer out
    out.puts "</pre>"
  end
  def escape txt
    txt.
      gsub(/\>/, '&gt;').
      gsub(/\</, '&lt;')
  end
end

class Snapshots
  def initialize
    files_temp = Dir.glob("snapshot.*.html")
    @files = if files_temp.length > 0
               files_temp.sort_by {|f| get_number f }
             else
               []
             end
  end
  def each
    @files.each { |f| yield f }
  end
  def next_number
    return 1 if @files.length == 0
    get_number(@files.last) + 1
  end
  def get_number file
    file.scan(/\d+/).shift.to_i
  end
end

def update_index 
  File.open("snapshots.menu.html", 'w') do |menu|
    menu.puts "<!DOCTYPE HTML><ol>"
    Snapshots.new.each do |link|
        menu.puts "<li><a href=\"#{link}\" target=\"snapshot\">#{link}</a></li>"
    end
    menu.puts "</ol>"
  end

  File.open("snapshots.html", 'w') do |index|
    index.puts <<EOF
      <!DOCTYPE HTML>
      <frameset cols="200,*">
        <frame src="snapshots.menu.html" />
        <frame src="" name="snapshot" />
      </frameset>      
EOF
  end
end

if __FILE__ == $PROGRAM_NAME
  main ARGV
end
