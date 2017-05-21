require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class DeleteCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      banner "delete -- Deletes (terminates) EC2 instance(s). Obviously, USE WITH CAUTION.\n\nCommand usage:\n\ndelete INSTANCE_NAME1 ...\n\nOptions:"

      opt :force, 'Force deletion, do not prompt.', default: false, short: '-f'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    ec2_wrapper.terminate_instances args, @sub_options
  end
end
