require 'eec2/ec2_wrapper'
require 'eec2/sub_command'

class ListCommand < SubCommand
  HOURS_PER_MONTH = 730

  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      banner "list -- lists the specified EC2 instance(s).\n\nCommand usage:\nlist [INSTANCE_NAME...]\n\nOptions:"

      # TODO: jafischer-2017-03-21 Need an option to list instances in multiple regions, different from the
      # global --region option (since it only makes sense for list). Or actually, maybe it would make sense... hmm.
      opt :long, 'Long format listing', default: false, short: '-l'
      opt :longer, 'Longer format listing', default: false, short: '-L'
      opt :state, 'List only instances with the specified state', type: String, default: nil, short: '-s'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    total_cost          = 0.0
    degraded_instances  = false

    # Longer implies long.
    @sub_options[:long] = true if @sub_options[:longer]

    instance_infos, name_width = ec2_wrapper.get_instance_info args

    # Print headings if in long mode.
    if !instance_infos.empty? and @sub_options[:long]
      heading = 'Name'.ljust(name_width + 1) +
        'State'.ljust(12) +
        'Public IP'.ljust(16) +
        (@sub_options[:longer] ? 'Private IP'.ljust(16) : '') +
        'Type'.ljust(12) +
        'Cost/Mo'.ljust(11)

      if @sub_options[:longer]
        heading += 'Cost/Hr'.ljust(9) +
          'Launch time'.ljust(25) +
          'Key'
      end
      puts heading.bg_green.brown.bold

      instance_infos.each do |i|
        # If --state specified, skip this instance if state doesn't match
        next if !@sub_options[:state].nil? and i[:state] != @sub_options[:state]

        if @sub_options[:long]
          cost       = ec2_wrapper.get_instance_cost i
          total_cost = total_cost + (i[:state] == 'running' ? cost : 0)

          line = "#{i[:name].ljust(name_width)} " +
            # ljust counts the escape characters, so account for that:
            i[:colorized_state].ljust(12 + i[:colorized_state].length - i[:state].length) +
            "#{i[:public_ip].ljust(16)}" +
            (@sub_options[:longer] ? "#{i[:private_ip].ljust(16)}" : '') +
            "#{i[:type].ljust(12)}" +
            "$#{('%.2f' % (cost * HOURS_PER_MONTH).round(2)).ljust(10)}"
          if @sub_options[:longer]
            line += "$#{('%.3f' % cost).ljust(8)}" +
              "#{i[:launch_time]}".ljust(25) +
              "#{i[:key]}"
          end

          puts line

          degraded_instances = (degraded_instances or ((i[:state_code] & 256) != 0))
        else
          puts i[:name]
        end
      end

      if @sub_options[:long] and !instance_infos.empty?
        puts "\nTotal current cost: $#{'%.2f' % total_cost.round(2)}/hr, $#{'%.2f' % (total_cost * HOURS_PER_MONTH).round(2)}/mo"
        puts '*Instance is running on hardware marked as degraded.' if degraded_instances
      end
    end
  end
end
