require 'eec2/sub_command'

class CreateCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      banner "create -- Creates EC2 instance(s).\n\nCommand usage:\n\ncreate INSTANCE_NAME1 ...\n\nOptions:"

      opt :image, 'AMI id', type: String, required: true
      opt :type, 'Instance type', type: String, required: true
      opt :key, 'Key name', type: String, required: true
      opt :sg, 'Security group', type: String, required: true
      opt :subnet, 'VPC Subnet ID', type: String, required: true
      opt :login, 'Name of login account for ssh', type: String, default: 'ec2-user'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    @ec2_wrapper.create_instances args, @sub_options
  end
end
