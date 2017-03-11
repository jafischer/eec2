#!/usr/bin/env ruby

# Auto-install gems we use:
def auto_install(gem_name)
  begin
    gem gem_name
  rescue LoadError
    puts "Auto-installing the #{gem_name} gem... (if this fails because it needs sudo, just execute 'sudo gem install #{gem_name}')"
    system "gem install #{gem_name}"
    Gem.clear_paths
  end

  require gem_name
end

# AWS SDK: see http://docs.aws.amazon.com/sdkforruby/api/index.html
# And http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html specifically for the EC2 client.
auto_install 'aws-sdk'

# Trollop: a command-line argument parser that I prefer over 'optparse'.
# See: https://github.com/ManageIq/trollop and http://trollop.rubyforge.org/
auto_install 'trollop'

require 'json'
require 'net/http'
require 'uri'

$script_path = File.expand_path File.dirname(__FILE__)

class Ec2Wrapper
  # Tried to make Ec2Wrapper inherit from Aws::EC2::Client, but couldn't get that to work. So we'll expose the
  # EC2 client instead.
  attr_accessor :ec2

  PRICE_LIST_FILE = 'ec2-pricelist.json'

  def initialize(global_parser, options)
    Aws.use_bundled_cert!

    aws_options               = {}
    aws_options[:region]      = options[:region] unless options[:region].nil?
    aws_options[:credentials] = Aws::Credentials.new(options[:key], options[:secret]) unless options[:key].nil?
    Aws.config.update aws_options unless aws_options.empty?

    begin
      if !File.exists? "#{Dir.home}/.aws/config" and (options[:region].nil? or options[:key].nil? or options[:secret].nil?)
        raise Aws::Errors::MissingRegionError
      end

      @ec2 = Aws::EC2::Client.new

      # Now that we've successfully initialized ec2, save the config:
      unless File.exists? "#{Dir.home}/.aws/config"
        Dir.mkdir "#{Dir.home}/.aws" unless Dir.exists? "#{Dir.home}/.aws"

        $stderr.puts "Creating #{Dir.home.gsub /\\/, '/'}/.aws/config"
        File.open("#{Dir.home}/.aws/config", 'w') do |f|
          contents = <<-EOS
          [default]
          output = json
          region = #{options[:region]}
          EOS
          f.puts contents.gsub /^  */, ''
        end

        $stderr.puts "Creating #{Dir.home.gsub /\\/, '/'}/.aws/credentials"
        File.open("#{Dir.home}/.aws/credentials", 'w') do |f|
          contents = <<-EOS
          [default]
          aws_access_key_id = #{options[:key]}
          aws_secret_access_key = #{options[:secret]}
          EOS
          f.puts contents.gsub /^  */, ''
        end
      end

    rescue Aws::Errors::MissingRegionError, Aws::Errors::MissingCredentialsError
      c1, c2 = '', ''
      c1, c2 = "\e[1;40;33m", "\e[0m" if $stdout.isatty

      $stderr.puts c1
      $stderr.puts "Looks like this is the first time you've run this script."
      $stderr.puts 'As a one-time configuration step: please run it again, specifying the AWS region and'
      $stderr.puts 'credentials (see below for help),'
      $stderr.puts c2
      global_parser.educate $stderr
      exit 1
    end
  end


  def get_instance_info(names)
    non_wildcard_names = {}
    names.each do |name|
      non_wildcard_names[name] = true unless name.include? '*'
    end

    if names.empty?
      resp = @ec2.describe_instances
    else
      resp = @ec2.describe_instances filters: [{ name: 'tag:Name', values: names }]
    end

    name_width     = 0
    instance_infos = []

    resp.reservations.each do |reservation|
      reservation.instances.each do |instance|
        instance_info = {
          name:        '<unnamed>',
          id:          instance.instance_id,
          state:       instance.state.name,
          state_code:  instance.state.code,
          launch_time: instance.launch_time,
          public_ip:   instance.public_ip_address.nil? ? '<n/a>' : instance.public_ip_address,
          private_ip:  instance.private_ip_address.nil? ? '<n/a>' : instance.private_ip_address,
          login_user:  'ec2-user',
          type:        instance.instance_type,
          region:      instance.placement.availability_zone,
          tenancy:     instance.placement.tenancy,
          key:         instance.key_name,
          key_path:    "#{Dir.home}/.ssh/#{instance.key_name}.pem"
        }
        instance.tags.each do |tag|
          if tag.key == 'Name' and !tag.value.empty?
            instance_info[:name] = tag.value
          elsif tag.key == 'login_user'
            instance_info[:login_user] = tag.value
          end
        end

        degraded = (instance_info[:state_code] & 256) != 0

        if $stdout.isatty
          # red=31 green=32 yellow=33 blue=34 pink=35 cyan=36 grey=37 black=38
          case instance_info[:state_code] & ~256
            # 0 (pending)
            when 0
              bold, bg, fg = 1, degraded ? 41 : 40, 33
            # 16 (running)
            when 16
              bold, bg, fg = 1, degraded ? 41 : 40, 32
            # 32 (shutting-down)
            when 32
              bold, bg, fg = 0, 47, 31
            # 48 (terminated)
            when 48
              bold, bg, fg = 0, 47, 30
            # 64 (stopping)
            when 64
              bold, bg, fg = 0, 40, 31
            # 80 (stopped).
            when 80
              bold, bg, fg = 1, 40, 31
            else
              bold, bg, fg = 0, degraded ? 41 : 40, 35
          end

          instance_info[:color_start] = "\e[#{bold};#{bg};#{fg}m"
          instance_info[:color_end]   = "\e[0m"
        else
          instance_info[:color_start] = ''
          instance_info[:color_end]   = ''
        end

        instance_info[:colorized_state] = ("#{instance_info[:color_start]}" +
          "#{instance_info[:state]}" +
          "#{degraded ? '*' : ''}" +
          "#{instance_info[:color_end]}").ljust(11 + instance_info[:color_start].length + instance_info[:color_end].length)

        name_width = [name_width, instance_info[:name].length].max

        # Keep track of which non-wildcard names have been found.
        non_wildcard_names.delete instance_info[:name] if non_wildcard_names.include? instance_info[:name]

        instance_infos.push instance_info
      end
    end

    instance_infos.sort! do |a, b|
      # This will properly sort instances with a numeric suffix, so that instance_9 will appear before instance_10
      if (a[:name].sub /_[^_]*$/, '') == (b[:name].sub /_[^_]*$/, '')
        (a[:name].sub /.*_/, '').to_i <=> (b[:name].sub /.*_/, '').to_i
      else
        a[:name] <=> b[:name]
      end
    end

    raise "No instances match '#{names.join ' '}'" if instance_infos.empty? unless names.empty?
    raise "No instances found named: '#{non_wildcard_names.keys.join ' '}'" unless non_wildcard_names.empty?

    return instance_infos, name_width
  end


  def get_instance_cost(instance_info)
    if @price_list.nil?
      # Get the pricing list for AmazonEC2
      # See https://aws.amazon.com/blogs/aws/new-aws-price-list-api/

      # If user's copy of pricelist exists, use it. Also, if for some reason the pricelist doesn't exist in the script dir,
      # then create and use one in the user's dir.
      # TODO: eventually, check the timestamp of the file and refresh if it's past a certain age.
      price_list_file = "#{Dir.home}/.aws/#{PRICE_LIST_FILE}"
      price_list_file = "#{$script_path}/#{PRICE_LIST_FILE}" if !File.exists? price_list_file and File.exists? "#{$script_path}/#{PRICE_LIST_FILE}"

      if !File.exists? price_list_file
        $stderr.puts 'Cached price list not found, retrieving from AWS URL... please wait.'
        ENV['SSL_CERT_FILE'] = "#{$script_path}/ca.pem" if File.exists? "#{$script_path}/ca.pem"
        uri                  = URI.parse 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonEC2/current/index.json'
        response             = Net::HTTP.get_response uri

        raise "Failed to get AWS price list: response code #{response.code}:\n#{response.body}" if response.code.to_i < 200 or response.code.to_i > 299

        File.open(price_list_file, 'w') do |f|
          f.write response.body
        end

        # This script just reduces the size of the pricelist file: No big deal if it doesn't exist or if node isn't installed.
        begin
          _ = `node #{$script_path}/prune-aws-pricelist.js #{price_list_file}`
        rescue Errno::ENOENT
          # ignored
        end

        @price_list = JSON.parse response.body
      else
        File.open(price_list_file, 'r') do |f|
          @price_list = JSON.parse(f.read)
        end
      end
    end

    @price_list['products'].each do |sku, product|
      # TODO: hard-coding US East for now; there's currently a mismatch between how regions are specified in EC2 and how
      # they're specified in the pricelist data.
      if product['attributes']['location'] == 'US East (N. Virginia)' and
        product['attributes']['instanceType'] == instance_info[:type]

        if product['attributes']['tenancy'] == instance_info[:tenancy] or
          (product['attributes']['tenancy'] == 'Shared' and instance_info[:tenancy] == 'default')
          # TODO: Until I can find out how to determine whether an instance is Reserved of On-Demand, we'll use the On-Demand pricing.
          unless @price_list['terms']['OnDemand'][sku].nil?
            # OnDemand terms have only one entry, so just grab the first one (same for priceDimensions):
            unit = @price_list['terms']['OnDemand'][sku].values.first['priceDimensions'].values.first['unit']
            if unit != 'Hrs'
              $stderr.puts "WARNING: Instance #{instance_info[:name]}'s price is measured in '#{unit}', not hours."
              $stderr.flush
            end
            return @price_list['terms']['OnDemand'][sku].values.first['priceDimensions'].values.first['pricePerUnit']['USD'].to_f
          end
        end
      end
    end

    $stderr.puts "WARNING: no price data found for instance type #{instance_info[:type]}"
    0.0
  end


  def run_instances(names, options)
    resp = @ec2.run_instances({
                                min_count:          names.count,
                                max_count:          names.count,
                                image_id:           options[:image],
                                key_name:           options[:key],
                                security_group_ids: [options[:sg]],
                                instance_type:      options[:type],
                                subnet_id:          options[:subnet]
                              })

    i = 0
    resp.instances.each do |inst|
      @ec2.create_tags({
                         resources: [inst.instance_id],
                         tags:      [
                                      { key: 'Name', value: names[i] },
                                      { key: 'login_user', value: options[:login] }
                                    ]
                       })
      i += 1
    end
  end

  def terminate_instances(names, options)
    instance_infos, _ = get_instance_info names
    instance_ids      = []
    puts 'About to terminate the following instances:'
    instance_infos.each { |i| instance_ids.push i[:id]; puts i[:name] }
    unless options[:force]
      print 'Are you sure? '
      input = $stdin.gets
      return unless input.start_with? 'y'
    end
    @ec2.terminate_instances(instance_ids: instance_ids)
  end

  def rename_instance(instance_id, new_name)
    @ec2.create_tags({
                       resources: [instance_id],
                       tags:      [{ key: 'Name', value: new_name }]
                     })
  end
end


class GlobalCommandWrapper
  def initialize(args)
    @args             = args

    # noinspection RubyStringKeysInHashInspection
    @sub_commands     = {
      'ls'     => lambda { |global_parser, global_options| ListCommand.new(global_parser, global_options) },
      'start'  => lambda { |global_parser, global_options| StartCommand.new(global_parser, global_options) },
      'stop'   => lambda { |global_parser, global_options| StopCommand.new(global_parser, global_options) },
      'ssh'    => lambda { |global_parser, global_options| SshCommand.new(global_parser, global_options) },
      'scp'    => lambda { |global_parser, global_options| ScpCommand.new(global_parser, global_options) },
      'ren'    => lambda { |global_parser, global_options| RenCommand.new(global_parser, global_options) },
      'create' => lambda { |global_parser, global_options| CreateCommand.new(global_parser, global_options) },
      'delete' => lambda { |global_parser, global_options| DeleteCommand.new(global_parser, global_options) },
    }

    # Directly placing #{@sub_commands.keys} in the string doesn't work, because (I think) @xxx is scoped to
    # the Parser object in the do block below.
    sub_command_names = @sub_commands.keys

    @global_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        eec2 -- Enhanced EC2 commands.

        Usage: #{File.basename __FILE__} [global options] COMMAND [command options] [COMMAND ARGUMENTS]
        Valid commands:
            #{sub_command_names.join ' '}

        Note: Help for each command can be displayed by entering -h after the command name.
        Global options:
      EOS

      banner long_banner.gsub /^        /, ''

      opt :region, 'Specify an AWS region (e.g. us-east-2, us-west-1)', type: String, short: '-r'
      opt :key, 'AWS access key id', type: String, short: '-k'
      opt :secret, 'AWS secret access key', type: String, short: '-s'

      stop_on sub_command_names
    end

    @global_options = Trollop::with_standard_exception_handling @global_parser do
      @global_parser.parse @args
    end

    global_usage "ERROR: Both --key and --secret must be specified together.\n\n" if @global_options[:key].nil? != @global_options[:secret].nil?
  end

  def global_usage(message)
    $stderr.puts message
    @global_parser.educate $stderr
    exit 1
  end

  def run_command
    global_usage "No command specified.\n\n" if @args.count < 1

    command = @args.shift

    # Is there a handler for this command?
    global_usage "Unknown command #{command}.\n\n" unless @sub_commands.include? command

    sub_command = @sub_commands[command].call @global_parser, @global_options

    sub_command.perform @args
  end
end


# Base class for sub-commands. Each contains a parser for the sub-options, and a method to perform the actual command.
# TODO: RubyMine isn't resolving any symbols from aws-sdk. I've disabled that inspection for now.
class SubCommand
  attr_accessor :sub_parser, :sub_options, :global_parser, :global_options, :ec2_wrapper

  def initialize(global_parser, global_options)
    @global_parser  = global_parser
    @global_options = global_options

    @ec2_wrapper = Ec2Wrapper.new(global_parser, global_options)
  end

  def perform(args)
    Trollop::with_standard_exception_handling @sub_parser do
      @sub_options = @sub_parser.parse args
    end

    begin
      _perform args
    rescue => ex
      $stderr.puts "ERROR: #{ex}"
    end
  end

  def _perform(args)

  end

  def sub_cmd_usage(message)
    $stderr.puts "#{message}\n\n"
    @global_parser.educate $stderr
    $stderr.puts "\n"
    @sub_parser.educate $stderr
    exit 1
  end
end


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


class StopCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      banner "stop -- stops the specified EC2 instance(s).\n\nCommand usage:\n\nstop INSTANCE_NAME...\n\nOptions:"

      opt :wait, 'Wait for the instance to come to a stopped state', default: false, short: '-w'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    instance_infos, _ = @ec2_wrapper.get_instance_info args
    instance_ids      = []
    instance_infos.each do |i|
      if i[:state] == 'running'
        puts "Stopping instance #{i[:name]}"
        instance_ids.push i[:id]
      else
        puts "Instance #{i[:name]} isn't running"
      end
    end
    @ec2_wrapper.ec2.stop_instances instance_ids: instance_ids


    if @sub_options[:wait]
      all_offline = false

      puts "Waiting for instance#{args.count > 1 ? 's' : ''} to stop..."
      until all_offline
        all_offline                 = true
        instance_infos, name_width = @ec2_wrapper.get_instance_info args
        instance_infos.each do |i|
          puts "#{i[:name].ljust(name_width)}  #{i[:colorized_state]}"
          all_offline = (all_offline and (i[:state] == 'stopped'))
        end
        puts ''
        sleep 1
      end
    end
  end
end


class SshCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      banner "ssh -- ssh to the specified EC2 instance(s) and optionally run a command.\n\nCommand usage:\n\nssh [options] INSTANCE_NAME...\n\nOptions:"

      opt :command, 'Rather than starting an ssh session, execute the specified command on the instance(s).', type: String, short: '-c'
      opt :log, 'Save output of command to [instance-name].log', default: false, short: '-l'
      opt :ignore, 'Ignore errors (such as some instances not in running state)', default: false, short: '-i'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: No instance name specified.' if args.empty?

    instance_infos, name_width = @ec2_wrapper.get_instance_info args

    command_line = @sub_options[:command]

    sub_cmd_usage 'ERROR: Multiple instances, but no command specified.' if command_line.nil? and instance_infos.count > 1

    instance_infos.each do |i|
      unless @sub_options[:ignore]
        raise "Instance #{i[:name]} is not running. State is '#{i[:state]}'" if i[:state] != 'running'
        raise "Can't find key file #{i[:key_path]}" unless File.exists? i[:key_path]
      end
      if command_line.nil?
        $stderr.puts "Connecting to #{i[:name]} as #{i[:login_user]}@#{i[:public_ip]}"
      else
        $stderr.puts "#{i[:name].ljust(name_width)} #{i[:login_user]}@#{i[:public_ip]}: '#{command_line}'"
      end

      if i[:state] == 'running'
        system "ssh -o ServerAliveInterval=100 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q -i #{i[:key_path]} #{i[:login_user]}@#{i[:public_ip]} '#{command_line}'"
        if $?.exitstatus == 255
          raise "\nThe ssh command failed -- it's possible that this instance requires a different login than '#{i[:login_user]}'.\nIf so, please add a 'login_user' tag to the instance, with the appropriate value (e.g. root, ubuntu, etc.)."
        end
      else
        $stderr.puts "Skipping non-running instance #{i[:name]}"
      end
    end
  end
end


class ScpCommand < SubCommand
  def initialize(global_parser, global_options)
    @sub_parser = Trollop::Parser.new do
      long_banner = <<-EOS
        scp -- Behaves like normal scp, but using instance names instead of user@ip_address.

        Command usage:

        scp [options] [INSTANCE_NAME:]file ... [INSTANCE_NAME:]file
        Note: wildcard is allowed when the last argument includes the instance name.

        Options:
      EOS

      banner long_banner.gsub /^ +/, ''

      opt :ignore, 'Ignore errors (such as some instances not in running state)', default: false, short: '-i'
      opt :recurse, 'Recursively copy entire directories.', default: false, short: '-r'
    end

    super(global_parser, global_options)
  end

  def _perform(args)
    sub_cmd_usage 'ERROR: Not enough arguments' if args.count < 2

    instance_map = {}
    key_file     = nil

    args.each do |arg|
      # First, convert any backslashes to forward slashes.
      arg = arg.gsub '\\', '/'
      if arg.match /:/
        instance_name                  = arg.sub /:.*/, ''
        instance_map[instance_name], _ = @ec2_wrapper.get_instance_info [instance_name]

        instance_map[instance_name].each do |i|
          unless @sub_options[:ignore]
            raise "Instance #{i[:name]} is not running. State is '#{i[:state]}'" if i[:state] != 'running'
            raise "Can't find key file #{i[:key_path]}" unless File.exists? i[:key_path]
          end
          if key_file.nil?
            key_file = i[:key_path]
          else
            raise 'ERROR: all instances must use same key file' if key_file != i[:key_path] unless @sub_options[:ignore]
          end
        end
      end
    end
    sub_cmd_usage 'ERROR: no paths contain instance names' if instance_map.empty?

    # Now convert the args into the required form for scp. E.g. convert 'instance-name:path' to 'user@ip-address:path'

    # Last arg is a special case: if it includes wildcards, we perform the scp command once for every returned instance.
    last_arg  = args.pop
    last_args = []
    if last_arg.match /:/
      instance_map[last_arg.sub /:.*/, ''].each do |i|
        if i[:state] == 'running'
          last_args.push last_arg.sub /.*:/, "#{i[:login_user]}@#{i[:public_ip]}:"
        else
          $stderr.puts "Skipping non-running instance #{i[:name]}"
        end
      end
    else
      last_args.push last_arg
    end

    last_args.each do |target_arg|

      source_args = []
      args.each do |arg|
        if arg.match /:/
          instance_map[arg.sub /:.*/, ''].each do |i|
            if i[:state] == 'running'
              source_args.push arg.sub /.*:/, "#{i[:login_user]}@#{i[:public_ip]}:"
            else
              $stderr.puts "Skipping non-running instance #{i[:name]}"
            end
          end
        else
          source_args.push arg
        end
      end

      puts "Executing scp with these file args: #{@sub_options[:recurse] ? '-r' : ''} #{source_args.join ' '} #{target_arg}"

      system "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q -i #{key_file} -p #{@sub_options[:recurse] ? '-r' : ''} #{source_args.join ' '} #{target_arg}"
    end
  end
end


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

    @ec2_wrapper.run_instances args, @sub_options
  end
end


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

    @ec2_wrapper.terminate_instances args, @sub_options
  end
end


#==================================
# Main

if __FILE__ == $0
  cmd = GlobalCommandWrapper.new ARGV
  cmd.run_command
end
