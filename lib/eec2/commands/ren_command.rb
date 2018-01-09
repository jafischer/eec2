require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class RenCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        ren -- Renames the specified EC2 instance(s)

        Command usage: #{'ren OLD_NAME [NEW_NAME]'.green}
        Note: supports wildcards in names, but only as the last character, e.g. 'ren some-prefix-* new-prefix-*'
        NEW_NAME can also be omitted (useful for clearing names of instances you've terminated). 

      EOS

      banner long_banner.gsub /^ {8}/, ''
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: no instances names specified' if args.empty?
    sub_cmd_usage 'ERROR: too many arguments' if args.length > 2
    
    old_name = args[0].dup
    new_name = args.length == 2 ? args[1].dup : ''
    
    wildcard = false
    if (old_name.include? '*') or (new_name.include? '*')
      sub_cmd_usage 'ERROR: both names must contain wildcard' if (old_name.include? '*') != (new_name.include? '*') unless (new_name.empty?)
      sub_cmd_usage 'ERROR: wildcard must be last character (e.g. eec2 ren old-* new-*)' unless (old_name.end_with? '*') and (new_name.end_with? '*' or new_name.empty?)
      wildcard = true
    end

    instance_infos, _ = ec2_wrapper.get_instance_info [old_name]

    # Need to make local copy of args, because if we attempt to modify args itself with a .sub! call, we get "can't modify frozen String (RuntimeError)"
    if wildcard
      old_name.sub! '*', ''
      new_name.sub! '*', ''
    end

    instance_infos.each do |i|
      new_instance_name = (wildcard && !new_name.empty?) ? i[:name].sub(old_name, new_name) : new_name
      ec2_wrapper.rename_instance i[:id], new_instance_name
    end
  end
end
