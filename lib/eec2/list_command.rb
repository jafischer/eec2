require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class ListCommand < SubCommand
  HOURS_PER_MONTH = 730

  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      banner "list -- lists the specified EC2 instance(s).\n\nCommand usage:\nlist [INSTANCE_NAME...]\n\nOptions:"

      opt :long, 'Long format listing, with instance details', default: false, short: '-l'
      opt :state, 'List only instances with the specified state', type: String, default: nil, short: '-s'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    total_cost         = 0.0
    degraded_instances = false

    instance_infos, name_width = @ec2_wrapper.get_instance_info args

    # Print headings if in long mode.
    if !instance_infos.empty? and @sub_options[:long]
      c1, c2 = '', ''
      c1, c2 = "\e[1;42;33m", "\e[0m" if $stdout.isatty
      puts c1 +
             'Name'.ljust(name_width + 1) +
             'State'.ljust(12) +
             'Public IP'.ljust(16) +
             'Private IP'.ljust(16) +
             'Type'.ljust(12) +
             'Cost/Hr'.ljust(9) +
             'Cost/Mo'.ljust(11) +
             'Launch time'.ljust(25) +
             'Key' +
             c2
    end

    instance_infos.each do |i|
      # If --state specified, skip this instance if state doesn't match
      next if !@sub_options[:state].nil? and i[:state] != @sub_options[:state]

      if @sub_options[:long]
        cost       = @ec2_wrapper.get_instance_cost i
        total_cost = total_cost + (i[:state] == 'running' ? cost : 0)

        # noinspection SpellCheckingInspection
        puts "#{i[:name].ljust(name_width)} " +
               "#{i[:colorized_state]} " +
               "#{i[:public_ip].ljust(16)}" +
               "#{i[:private_ip].ljust(16)}" +
               "#{i[:type].ljust(12)}" +
               "$#{('%.3f' % cost).ljust(8)}" +
               "$#{('%.2f' % (cost * HOURS_PER_MONTH).round(2)).ljust(10)}" +
               "#{i[:launch_time]}".ljust(25) +
               "#{i[:key]}"

        degraded_instances = (degraded_instances or ((i[:state_code] & 256) != 0))
      else
        puts i[:color_start] + i[:name] + i[:color_end]
      end
    end

    if @sub_options[:long] and !instance_infos.empty?
      puts "\nTotal current cost: $#{'%.2f' % total_cost.round(2)}/hr, $#{'%.2f' % (total_cost * HOURS_PER_MONTH).round(2)}/mo"
      puts '*Instance is running on hardware marked as degraded.' if degraded_instances
    end
  end
end
