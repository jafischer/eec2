require 'eec2/ec2_wrapper'
require 'eec2/sub_command'


class IpCommand < SubCommand
  def initialize(global_parser, global_options, sub_command)
    @sub_command = sub_command
    @sub_parser  = Trollop::Parser.new do
      long_banner = <<-EOS
        ip-add, ip-rm, ip-ls -- Commands for instance private IP addresses.

        Command usage:
        ip-add [options] INSTANCE...
        ip-rm [options] INSTANCE ADDRESS...
        ip-ls [options] INSTANCE...

        Options:
      EOS

      banner long_banner.gsub /^ {8}/, ''

      opt :count, '[ip-add only] Number of addresses to add', default: 1, short: '-c'
      opt :long, '[ip-ls only] Long format listing', default: false, short: '-l'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    case @sub_command
      when 'add'
        add args
      when 'rm'
        remove args
      when 'ls'
        list args
      else
        raise "Unknown ip command: #{@sub_command}"
    end
  end

  def add(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    instance_infos, _ = @ec2_wrapper.get_instance_info args
    instance_infos.each do |i|
      i[:net_interfaces].each do |iface|
        @ec2_wrapper.ec2.assign_private_ip_addresses(network_interface_id: iface.network_interface_id, secondary_private_ip_address_count: @sub_options[:count])
        puts "Instance #{i[:name]}: added #{@sub_options[:count]} private IP address#{@sub_options[:count] > 1 ? 'es' : ''} to interface #{iface.network_interface_id}"
      end
    end
  end

  def remove(args)
    sub_cmd_usage 'ERROR: No instance name and/or IP addresses specified.' if args.count < 2

    instance_name     = args.shift
    instance_infos, _ = @ec2_wrapper.get_instance_info [instance_name]
    # Even though this command is designed to work with only a single instance name parameter, if
    # you pass a wildcard, and it matches to several instances, I can't think of a reason to error out.
    instance_infos.each do |i|
      i[:net_interfaces].each do |iface|
        # iface.private_ip_addresses is an array of structures, so extract just the ip address strings:
        private_ips            = iface.private_ip_addresses.map {|addr| addr.private_ip_address}
        # Ensure we don't try to remove the primary private ip address
        args                   = args - [iface.private_ip_address]
        # Find the intersection
        remove_from_this_iface = private_ips & args
        unless remove_from_this_iface.empty?
          @ec2_wrapper.ec2.unassign_private_ip_addresses(network_interface_id: iface.network_interface_id,
                                                         private_ip_addresses: remove_from_this_iface)
          puts "Instance #{i[:name]}, interface #{}: removed #{remove_from_this_iface}"
          args = args - remove_from_this_iface

          break if args.empty?
        end
      end
    end

    $stderr.puts "Note: the following addresses were not found in #{instance_name}: #{args}" unless args.empty?
  end

  def list(args)
    instance_infos, name_width = @ec2_wrapper.get_instance_info args

    name_width = [name_width, 'Instance '.length].max

    if !instance_infos.empty? and @sub_options[:long]
      c1, c2 = '', ''
      c1, c2 = "\e[1;42;33m", "\e[0m" if $stdout.isatty
      puts c1 +
             'Instance'.ljust(name_width + 1) +
             'Iface'.ljust(16) +
             'Address'.ljust(17) +
             'Type'.ljust(12) +
             c2
    end

    instance_infos.each do |i|
      i[:net_interfaces].each do |iface|
        iface.private_ip_addresses.each do |addr|
          if @sub_options[:long]
            puts "#{i[:name].ljust(name_width + 1)}" +
                   "#{iface.network_interface_id.ljust(16)}" +
                   "#{addr.private_ip_address.ljust(17)}" +
                   "#{addr.private_ip_address == iface.private_ip_address ? 'Primary' : 'Secondary'}"
          else
            # For short-form, just print the ip addresses, nothing else, so that the output can be used directly in
            # other scripts.
            print "#{addr.private_ip_address} "
          end
        end
      end
      puts '' unless @sub_options[:long]
    end
  end
end
