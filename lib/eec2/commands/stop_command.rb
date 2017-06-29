require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class StopCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        stop -- stop the specified EC2 instance(s)

        Command usage: #{'stop [options] INSTANCE_NAME...'.green}
      EOS

      banner long_banner.gsub(/^ {8}/, '')

      opt :force, 'Stop the instance even if it is controlled by OpsWorks', default: false
      opt :wait, 'Wait for the instance to come to a stopped state', default: false
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    instance_infos, _ = ec2_wrapper.get_instance_info args
    instance_ids      = []
    instance_infos.each do |i|
      if i[:state] == 'running'
        puts "Stopping instance #{i[:name]}"
        instance_ids.push i[:id]
      else
        puts "Instance #{i[:name]} isn't running"
      end
    end

    unless @sub_options[:force]
      tags = ec2_wrapper.get_tag instance_ids, 'opsworks:instance'

      unless tags.empty?
        opsworks_instance_ids = tags.map &:resource_id
        opsworks_instance_infos = instance_infos.select { |i| opsworks_instance_ids.include? i[:id]}
        raise "One or more instances are controlled by OpsWorks; specify --force if this is really intended:\n    #{(opsworks_instance_infos.map { |oi| oi[:name]}).join ', '}"
      end
    end

    # noinspection RubyResolve
    ec2_wrapper.ec2.stop_instances instance_ids: instance_ids

    if @sub_options[:wait]
      all_offline = false

      puts "Waiting for instance#{args.count > 1 ? 's' : ''} to stop..."
      until all_offline
        all_offline                = true
        instance_infos, name_width = ec2_wrapper.get_instance_info args
        instance_infos.each do |i|
          puts "#{i[:name].ljust(name_width)}  #{i[:colorized_state]}"
          all_offline = (all_offline and (i[:state] == 'stopped'))
        end
        puts ''
        sleep 1
      end
    end
  end
end
