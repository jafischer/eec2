require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class SshCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      banner "ssh -- ssh to the specified EC2 instance(s) and optionally run a command.\n\nCommand usage:\n\nssh [options] INSTANCE_NAME...\n\nOptions:"

      opt :command, 'Rather than starting an ssh session, execute the specified command on the instance(s).', type: String, short: '-c'
      opt :log, 'Save output of command to [instance-name].log', default: false, short: '-l'
      opt :ignore, 'Ignore errors (such as some instances not in running state)', default: false, short: '-i'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    instance_infos, name_width = @ec2_wrapper.get_instance_info args

    command_line = @sub_options[:command]

    sub_cmd_usage 'ERROR: Multiple instances, but no command specified.' if command_line.nil? and instance_infos.count > 1

    instance_infos.each do |i|
      unless @sub_options[:ignore]
        raise "Instance #{i[:name]} is not running. State is '#{i[:state]}'" if i[:state] != 'running'
        raise "Can't find key file #{i[:key_path]}" unless File.exists? i[:key_path]
      end
      if command_line.nil?
        $stderr.puts "Connecting to #{i[:name]} as #{i[:login_user]}@#{i[:public_ip]}".green.bold
      else
        $stderr.puts "#{i[:name].ljust(name_width)} #{i[:login_user]}@#{i[:public_ip]}, command: ".green.bold + command_line
      end

      if i[:state] == 'running'
        system "ssh -o ServerAliveInterval=100 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q -i #{i[:key_path]} #{i[:login_user]}@#{i[:public_ip]} '#{command_line}'"
        if $?.exitstatus == 255
          raise "\nThe ssh command failed -- it's possible that this instance requires a different login than '#{i[:login_user]}'.\nIf so, please add a 'login_user' tag to the instance, with the appropriate value (e.g. root, ubuntu, etc.)."
        end
      else
        $stderr.puts "Skipping non-running instance #{i[:name]}"
      end
    end
  end
end
