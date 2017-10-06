require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class TagCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        tag -- Adds tags to the specified EC2 instance(s). With no options, lists all tags for the instance(s).

        Command usage: #{'tag INSTANCE... [--tag TAG [--value VALUE]]'.green}

      EOS

      banner long_banner.gsub /^ {8}/, ''

      opt :tag, 'Tag name', type: String
      opt :value, 'Tag value (if no value specified, tag is deleted)', type: String
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    if @sub_options[:tag].nil?
      ec2_wrapper.list_tags args
    else
      ec2_wrapper.add_tag args, @sub_options[:tag], @sub_options[:value]
    end
  end
end
