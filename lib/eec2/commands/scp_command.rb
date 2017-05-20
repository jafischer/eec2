require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class ScpCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        scp -- Behaves like normal scp, but using instance names instead of user@ip_address.

        Command usage:

        scp [options] [INSTANCE_NAME:]file ... [INSTANCE_NAME:]file
        Note: wildcard is allowed when the last argument includes the instance name.

        Options:
      EOS

      banner long_banner.gsub /^ +/, ''

      opt :ignore, 'Ignore errors (such as some instances not in running state)', default: false, short: '-i'
      opt :recurse, 'Recursively copy entire directories.', default: false, short: '-r'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: Not enough arguments' if args.count < 2

    instance_map = {}
    key_file     = nil

    args.each do |arg|
      # First, convert any backslashes to forward slashes.
      arg = arg.gsub '\\', '/'
      if arg.match /:/
        instance_name                  = arg.sub /:.*/, ''
        instance_map[instance_name], _ = @ec2_wrapper.get_instance_info [instance_name]

        instance_map[instance_name].each do |i|
          unless @sub_options[:ignore]
            raise "Instance #{i[:name]} is not running. State is '#{i[:state]}'" if i[:state] != 'running'
            raise "Can't find key file #{i[:key_path]}" unless File.exists? i[:key_path]
          end
          if key_file.nil?
            key_file = i[:key_path]
          else
            raise 'ERROR: all instances must use same key file' if key_file != i[:key_path] unless @sub_options[:ignore]
          end
        end
      end
    end
    sub_cmd_usage 'ERROR: no paths contain instance names' if instance_map.empty?

    # Now convert the args into the required form for scp. E.g. convert 'instance-name:path' to 'user@ip-address:path'

    # Last arg is a special case: if it includes wildcards, we perform the scp command once for every returned instance.
    last_arg  = args.pop
    last_args = []
    if last_arg.match /:/
      instance_map[last_arg.sub /:.*/, ''].each do |i|
        if i[:state] == 'running'
          last_args.push last_arg.sub /.*:/, "#{i[:login_user]}@#{i[:public_ip]}:"
        else
          $stderr.puts "Skipping non-running instance #{i[:name]}"
        end
      end
    else
      last_args.push last_arg
    end

    last_args.each do |target_arg|

      source_args = []
      args.each do |arg|
        if arg.match /:/
          instance_map[arg.sub /:.*/, ''].each do |i|
            if i[:state] == 'running'
              source_args.push arg.sub /.*:/, "#{i[:login_user]}@#{i[:public_ip]}:"
            else
              $stderr.puts "Skipping non-running instance #{i[:name]}"
            end
          end
        else
          # On Windows, the scp command that I use (the one that comes with Git) doesn't work well with backslashes.
          # For instance, "scp .\file <host>:" will correctly copy the file, but it keeps the backslash in the name!
          # So you end up with a file on the remote system named ".\file".
          source_args.push arg.gsub /\\/, '/'
        end
      end

      puts 'Executing scp with these file args:'.green.bold + " #{@sub_options[:recurse] ? '-r' : ''} #{source_args.join ' '} #{target_arg}"

      system "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q -i #{key_file} -p #{@sub_options[:recurse] ? '-r' : ''} #{source_args.join ' '} #{target_arg}"
    end
  end
end
