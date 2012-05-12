require 'digest/sha1'
require 'yaml'
require 'find'
require 'fileutils'
require 'set'

EXTENSIONS = %w(png jpeg jpg gif)
HASH_DIGEST = Digest::SHA1

FILEUTILS_VERBOSE = true
FILEUTILS_NOOP = false

# generate an md5 hash of the 
def hash_file path, hash_store
	hexdigest = HASH_DIGEST.hexdigest(open(path, 'rb') { |io| io.read })
	hash_store[hexdigest] << path
end

def read_dir path, hash_store
	count = 0
	Find.find(path) { |file| (hash_file(file, hash_store); count += 1) if digest?(file) }
	count
end

def digest? path
	# makes sure the file is a file and the extension is allowed,
	# the first character from extname should be a "." and is trimmed off.
	File.file?(path) && EXTENSIONS.include?(File.extname(path)[1..-1])
end

def convert_slashes path
	path.gsub('\\', '/')
end

def delete_files files
	puts # newline
	files.each { |f| FileUtils.rm f, :verbose => FILEUTILS_VERBOSE, :noop => FILEUTILS_NOOP }
end

def delete_dups hash_store
	# keep track of previously selected parent directories you chose to keep files in
	priority_parent_dirs = Set.new

	# select only the pairs where the values array size > 1 (multiple files with the same hash)
	dups = hash_store.select { |k,v| v.size > 1 }

	# iterate the duplicates
	dups.each do |md5, files|
		orig_size = files.size

		# sanity check to make sure not all files are deleted
		files_kept = []

		files.delete_if do |f|
			# see if the parent directory of this file is a "priority directory"
			# files that are in priority directories are not deleted
			dir = convert_slashes File.dirname(f)
			keep_me = priority_parent_dirs.include? dir
			if keep_me
				puts "Keeping #{f} due to being in the same directory previously kept file"
				files_kept << f
			end
			keep_me
		end

		# if the size is the same, nothing was deleted due to priorty, so let the user
		# manually select the file(s) to keep
		if files.size == orig_size
			puts "The following files are duplicates:"
			files.each_with_index { |file, index| puts "#{index} - #{file}" }
			puts "#{files.size} - [enter your own directory]"
			print "Select the file(s) to KEEP > "
			keep_index = ($stdin.gets).chomp.split(/\s*,?\s*/)

			if keep_index.size == 1 && keep_index[0] == files.size.to_s
				print "Enter a directory to move the file to > "
				path = $stdin.gets.chomp
				if File.directory? path
					puts # newline
					path = convert_slashes path
					FileUtils.cp files[0], path, :verbose => FILEUTILS_VERBOSE, :noop => FILEUTILS_NOOP
					priority_parent_dirs << path.chomp('/')
					delete_files files
				else
					puts "Directory #{path} does not exist, moving on..."
				end
			elsif keep_index.all? { |i| i =~ /^[0-9]+$/ && i.to_i < files.size }
				keep_index.each do |i| 
					path = files.delete_at(i.to_i)
					files_kept << path
					priority_parent_dirs << convert_slashes(File.dirname(path)).chomp('/')
				end
				delete_files files
			else
				puts "Invalid index given (#{keep_index.inspect}), none of the #{files.size} files will be deleted"
			end
		elsif files_kept.size > 0
			# delete all files in the array
			delete_files files
		else
			puts "[Error] Line #{__LINE__} of #{__FILE__} shouldn't execute"
		end

		puts # newline
	end
end

def die_usage exit_return = 1
	puts <<-EOF
USAGE: ruby #{__FILE__} DIR... > output_file.yaml

DIR = one or more directories to scan

It's suggested that you pipe the output to a file so it can be used
by move_files.rb to consolidate duplicates to a single directory
EOF
	exit exit_return
end

if __FILE__ == $0
	die_usage if ARGV.size < 1 || %w(-h --help -?).any? { |p| ARGV.include? p }
	do_debug = ARGV.delete("--debug") != nil
	do_delete = ARGV.delete("--delete")

	# each value is automatically set as an array
	hash_store = Hash.new { |h,k| h[k] = [] }

	files_read = 0
	ARGV.each do |dir|
		files_read += read_dir(dir, hash_store) if File.directory?(dir)
	end

	if do_debug
		$stderr.puts "Hashed #{files_read} files"
	end

	if do_delete
		delete_dups hash_store
	else
		puts YAML.dump(hash_store)
	end
end