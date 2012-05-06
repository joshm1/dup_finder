require 'digest/md5'
require 'yaml'
require 'find'

EXTENSIONS = %w(png jpeg jpg gif)
HASH_DIGEST = Digest::MD5

# generate an md5 hash of the 
def hash_file path, hash_store
	md5 = HASH_DIGEST.hexdigest File.read path
	hash_store[md5] << path
end

def read_dir path, hash_store
	Find.find(path) { |file| hash_file(file, hash_store) if digest?(file) }
end

def digest? path
	# makes sure the file is a file and the extension is allowed,
	# the first character from extname should be a "." and is trimmed off.
	File.file?(path) && EXTENSIONS.include?(File.extname(path)[1..-1])
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

	# each value is automatically set as an array
	hash_store = Hash.new { |h,k| h[k] = [] }

	ARGV.each do |dir|
		read_dir(dir, hash_store) if File.directory?(dir)
	end

	puts YAML.dump(hash_store)
end