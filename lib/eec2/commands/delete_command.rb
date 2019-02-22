require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class DeleteCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Optimist::Parser.new do
      long_banner = <<-EOS
        delete -- Delete (terminate) EC2 instance(s)

        Command usage: #{'delete [options] INSTANCE_NAME...'.green}
      EOS

      banner long_banner.gsub(/^ {8}/, '')

      opt :force, "Force deletion, do not prompt. It goes without saying, #{'USE WITH CAUTION'.red.bold}.", default: false
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    ec2_wrapper.terminate_instances args, @sub_options
  end
end
