require "pathname"
require "yaml"
require "open3"

def exec(command)
	out, err, status = Open3.capture3(command)
	if status != 0
		raise Exception.new("status code error: #{status}, command=[#{command}]")
	end
	if err != ""
		raise Exception.new("stderr emitted: #{err}")
	end
	return out
end

class DfRow
	attr_reader :disk, :block_num, :used, :available, :capacity, :mount

	def initialize(
		disk, block_num, used, available, capacity, mount
		)
		@disk = disk
		@block_num = block_num
		@used = used
		@available = available
		@capacity = capacity
		@mount = mount
	end

	def self.parse(str)
		regex = /^(\S|\S[\S ]*\S)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(.*)$/
		m = regex.match(str)
		if ! m 
			return nil
		end
		disk = m[1].strip()
		block_num = m[2].to_i
		used = m[3].to_i
		available = m[4].to_i
		capacity = m[5].to_i
		mount = m[6].strip()
		return DfRow.new(disk, block_num, used, available, capacity, mount)
	end
end

class App
	attr_reader :config
	def main
		config_path = Pathname.new(__FILE__).parent.parent + "config/config.yml"
		@config = YAML.load(config_path.read())

		cmd = "df -P"
		out = exec(cmd)
		lines = out.split("\n")
		regex = /^(\S|\S[\S ]*\S)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(.*)$/

		target_disk = config["disk"]

		row = lines.map {|x| DfRow.parse(x) }.select {|x| x != nil }
			.select {|x| x.disk.include?(target_disk) }
			.first
		if row == nil
			puts "no disk matches. (#{target_disk})"
			puts out
			return
		end

		if row.capacity >= config["rate"].to_i
			puts "disk usage is high! (#{target_disk})"
			puts out
		end
	end
end

app = App.new
app.main