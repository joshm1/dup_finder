require 'fileutils'
require 'yaml'

# Returns the basename of the parent directory of a file, after
# removing excess spaces if the basename
def parent_dir path
	(File.basename File.dirname path).gsub(/\s+/, ' ').strip
end

# returns an array of error messages. An empty array is good.
def process_dups dups, output_paths
	priorities = {}
	errors = []

	dups.each do |hash, files|
		# HACK: eliminate newlines in file names, not sure why they were there in the first place
		files.map! { |f| f.gsub("\n", ' ') }

		# identify all unique parent directory names for the files
		parent_dirs = files.map { |f| parent_dir(f) }.uniq.sort

		if parent_dirs.size > 1
			# if there are different parent directory names for the same file,
			# let the user select which one to use
			unless priorities.include? parent_dirs
				parent_dirs.each_with_index { |d, i| puts "#{i} = #{d.inspect}" }
				print "Select Index > "
				index = ($stdin.gets).chomp.to_i
				priorities[parent_dirs] = parent_dirs[index]
				puts # print newline
			end
			parent_dir = priorities[parent_dirs]
		elsif parent_dirs.size == 1
			parent_dir = parent_dirs[0]
		else
			puts "Invalid parent directories for #{hash}: #{parent_dirs.inspect}"
		end

		readable_files = files.select { |f| File.readable?(f) }
		if readable_files.size == 0
			errors << "Unable to read any of the following files:\n - #{files.join("\n - ")}"
		else
			output_paths[parent_dir] << readable_files[0]
		end
	end

	errors
end

def write_new_files output_dir, output_paths
	output_paths.each do |parent_dir, paths|
		dir = File.join(output_dir, parent_dir)
		FileUtils.mkdir_p dir, :verbose => true
		paths.each do |path|
			FileUtils.cp path, dir, :verbose => true
		end
	end
end

def die_usage exit_return = 1
	puts <<-EOF
USAGE: ruby #{__FILE__} OUTPUT_DIR YAML_DUP_FILES...

OUTPUT_DIR = the directory to copy the files to
YAML_DUP_FILES = one or more yaml files that specify files by fingerprint

NOTE: Copied files will have the same parent directory as the original 
location. For example, if OUTPUT_DIR is C:\\Pictures and a
YAML_DUP_FILE specifies a file at D:\\Pictures\\2012-05-06\\file.jpg, 
it will be copied to C:\\Pictures\\2012-05-06\\file.jpg
EOF
	exit exit_return
end

if __FILE__ == $0
	die_usage if ARGV.count < 2 || %w(-h --help -?).any? { |p| ARGV.include? p }

	# the directory all files will be copied to
	output_dir = ARGV[0]

	# key = parent directory, value = array of files to write to the parent directory
	output_paths = Hash.new { |h,k| h[k] = [] }

	errors = []
	ARGV[1..-1].each do |yaml_file|
		dups = YAML.load File.read yaml_file
		errors += process_dups dups, output_paths
	end

	if errors.size == 0
		if output_paths.size > 0
			file_count = output_paths.inject(0) { |sum, paths| sum += paths.size }
			print "I will copy #{file_count} file(s) to #{output_dir},\nand may override existing files. Do you want me to continue? (y/n) > "
			ans = ($stdin.gets).chomp
			if ans =~ /^y/i
				exit 0
				write_new_files output_dir, output_paths
			else
				puts "Exiting..."
			end
		else
			puts "Nothing to write o_O"
		end
	else
		puts "\nERRORS:\n\n" + errors.join("\n\n")
	end
end