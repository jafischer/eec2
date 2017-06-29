require 'concurrent'

require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class ScpCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        scp -- Behaves like normal scp, but using instance names instead of user@ip_address.

        Command usage: #{'scp [options] [INSTANCE_NAME:]file ... [INSTANCE_NAME:]file'.green}
        Note: wildcards are allowed in the final argument only.
        Example:
          eec2 scp serverfiles/* myserver-*:
            --> Copies files to all instances with names beginning with 'myserver-'.
      EOS
      # TODO: Implement wildcards in source paths as well.
      #   Note: wildcards are allowed in both source and target paths.
      #   Examples:
      #     eec2 scp serverfiles/* myserver-*:
      #       --> Copies files TO all instances with names beginning with 'myserver-'.
      #     eec2 scp myserver-*:*.log .
      #       --> Copies files FROM all instances with names beginning with 'myserver-'
      #           In this example, the last argument must be a directory; files will be placed
      #           in subdirectories using the instance names.
      #
      # EOS

      banner long_banner.gsub /^ +/, ''

      opt :ignore, 'Ignore errors (such as some instances not in running state)', default: false, short: '-i'
      opt :recurse, 'Recursively copy entire directories.', default: false, short: '-r'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: Not enough arguments' if args.count < 2

    all_instances = []
    instance_map  = {}
    key_file      = nil

    args.each do |arg|
      if arg.match /:/
        instance_name                  = arg.sub /:.*/, ''
        instance_map[instance_name], _ = ec2_wrapper.get_instance_info [instance_name]
        all_instances                  += instance_map[instance_name]

        instance_map[instance_name].each do |i|
          unless @sub_options[:ignore]
            raise "Instance #{i[:name]} is not running. State is '#{i[:state]}'" if i[:state] != 'running'
            raise "Can't find key file #{i[:key_path]}" unless File.exists? i[:key_path]
          end
          if key_file.nil?
            key_file = i[:key_path]
          else
            raise 'All instances must use same key file' if key_file != i[:key_path] unless @sub_options[:ignore]
          end
        end
      end
    end
    sub_cmd_usage 'ERROR: no paths contain instance names' if instance_map.empty?

    ec2_wrapper.check_login_names all_instances

    # Now convert the args into the required form for scp. E.g. convert 'instance-name:path' to 'user@ip-address:path'

    # Last arg is a special case: if it matches multiple instances (e.g. if it contains wildcards, or if multiple
    # instances share the same name), we perform the scp command once for every returned instance.
    last_arg  = args.pop
    last_args = []
    if last_arg.match /:/
      instance_map[last_arg.sub /:.*/, ''].each do |i|
        if i[:state] == 'running'
          last_args.push last_arg.sub /.*:/, "#{i[:login_user]}@#{i[:public_ip]}:"
        else
          $stderr.puts "Skipping non-running instance #{i[:name]}".brown
        end
      end
    else
      # Last arg doesn't contain a colon, so it's a local file path.
      last_args.push last_arg.gsub '\\', '/'
    end

    futures = {}
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
          source_args.push arg.gsub '\\', '/'
        end
      end

      # puts 'Executing scp with these file args:'.green.bold + " #{@sub_options[:recurse] ? '-r' : ''} #{source_args.join ' '} #{target_arg}"
      scp_command = 'scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ' + (last_args.count == 1 ? '' : '-q ') +
        "-i #{key_file} -p #{@sub_options[:recurse] ? '-r' : ''} #{source_args.join ' '} #{target_arg}"
      if last_args.count == 1
        system scp_command
      else
        instance_name          = target_arg.sub(/.*@/, '').sub(/:.*/, '')
        futures[instance_name] = Concurrent::Future.execute {`#{scp_command}`}
      end
    end

    # Now wait for all of the futures, if any, to complete.
    puts 'Waiting for commands to complete...'.brown unless futures.empty?
    futures.each do |name, future|
      output = future.value
      unless output.empty?
        $stderr.puts "Output from #{name}".green.bold
        print output
      end
      $stderr.puts "#{name}: the ssh command failed".red.bold if future.rejected?
    end
  end
end
