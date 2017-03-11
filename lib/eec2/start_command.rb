require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class StartCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      banner "start -- starts the specified EC2 instance(s).\n\nCommand usage:\n\nstart [options] INSTANCE_NAME...\n\nOptions:"
      opt :wait, 'Wait for the instance to come to a running state', default: true, short: '-w'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    instance_infos, _ = @ec2_wrapper.get_instance_info args
    instance_ids      = []
    instance_infos.each do |i|
      if i[:state] != 'running'
        puts "Starting instance #{i[:name]}"
        instance_ids.push i[:id]
      else
        puts "Instance #{i[:name]} is already running"
      end
    end
    @ec2_wrapper.ec2.start_instances instance_ids: instance_ids

    if @sub_options[:wait]
      all_online = false

      puts "Waiting for instance#{args.count > 1 ? 's' : ''} to finish starting..."
      until all_online
        all_online                 = true
        instance_infos, name_width = @ec2_wrapper.get_instance_info args
        instance_infos.each do |i|
          puts "#{i[:name].ljust(name_width)}  #{i[:colorized_state]}"
          all_online = (all_online and (i[:state] == 'running'))
        end
        puts ''
        sleep 1
      end
    end
  end
end
