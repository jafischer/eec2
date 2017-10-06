require 'concurrent'

require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class SshCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        ssh -- login to the specified EC2 instance(s) and optionally run a command

        Command usage: #{'ssh [options] INSTANCE_NAME...'.green}
      EOS

      banner long_banner.gsub(/^ {8}/, '')

      opt :command, 'Rather than starting an ssh session, execute the specified command on the instance(s).', type: String
      # TODO: implement --log
      # opt :log, 'Save output of command to [instance-name].log', default: false
      opt :ignore, 'Ignore errors (such as some instances not in running state)', default: false
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    instance_infos, _ = ec2_wrapper.get_instance_info args
    command_line               = @sub_options[:command]

    sub_cmd_usage 'ERROR: Multiple instances, but no command specified.' if command_line.nil? and instance_infos.count > 1

    ec2_wrapper.check_login_names instance_infos

    # Check all the instances before running any commands.
    instance_infos.each do |i|
      if @sub_options[:ignore]
        puts "WARNING: Instance #{i[:name]} is not running. State is '#{i[:state]}'" if i[:state] != 'running'
        puts "WARNING: Can't find key file #{i[:key_path]}" unless File.exists? i[:key_path]
      else
        raise "Instance #{i[:name]} is not running. State is '#{i[:state]}'" if i[:state] != 'running'
        raise "Can't find key file #{i[:key_path]}" unless File.exists? i[:key_path]
      end
    end

    futures = {}
    instance_infos.each do |i|
      if (i[:state] == 'running') && (File.exists? i[:key_path])
        ssh_command = 'ssh -o ServerAliveInterval=100 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q ' +
          "-i #{i[:key_path]} #{i[:login_user]}@#{i[:public_ip]} '#{command_line}'"
        # If multiple instances, then run the commands asynchronously.
        if instance_infos.count == 1
          system ssh_command
          $stderr.puts 'The ssh command failed'.red.bold if $?.exitstatus != 0 && !command_line.nil?
        else
          # Using the whole instance object as the key for the futures hash here, because we can't use
          # the instance name, since multiple instances might have the same name.
          futures[i] = Concurrent::Future.execute { `#{ssh_command}` }
        end
      end
    end

    # Now wait for all of the futures, if any, to complete.
    puts 'Waiting for commands to complete...'.brown unless futures.empty?
    futures.each do |i, future|
      output = future.value
      unless output.empty?
        $stderr.puts "Output from #{i[:name]}".green.bold
        print output
      end
      $stderr.puts "#{i[:name]}: the ssh command failed".red.bold if future.rejected? && !command_line.empty?
    end
  end
end
