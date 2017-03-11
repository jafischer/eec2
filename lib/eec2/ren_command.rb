require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class RenCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        ren -- Renames the specified EC2 instance(s).

        Command usage:

        ren OLD_NAME NEW_NAME
        Note: supports wildcards in names, but only as the last character, e.g. 'ren some-prefix-* new-prefix-*'
        NEW_NAME can also be empty (useful for clearing names of instances you've terminated). 

        Options:
      EOS

      banner long_banner.gsub /^        /, ''
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: exactly two names must be specified (old name and new name)' unless args.length == 2
    wildcard = false
    if (args[0].include? '*') or (args[1].include? '*')
      sub_cmd_usage 'ERROR: both names must contain wildcard' if (args[0].include? '*') != (args[1].include? '*') unless (args[1].empty?)
      sub_cmd_usage 'ERROR: wildcard support is limited to prefix only (e.g. eec2 ren oldprefix-* newprefix-*)' unless (args[0].end_with? '*') and (args[1].end_with? '*' or args[1].empty?)
      wildcard = true
    end

    instance_infos, _ = @ec2_wrapper.get_instance_info [args[0]]

    if wildcard
      args[0].sub! '*', ''
      args[1].sub! '*', ''
    end

    instance_infos.each do |i|
      new_name = wildcard ? i[:name].sub(args[0], args[1]) : args[1]
      @ec2_wrapper.rename_instance i[:id], new_name
    end
  end
end
