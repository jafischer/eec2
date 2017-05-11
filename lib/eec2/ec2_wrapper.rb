# AWS SDK: see http://docs.aws.amazon.com/sdkforruby/api/index.html
# And http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html specifically for the EC2 client.
require 'aws-sdk'

# Trollop: a command-line argument parser that I prefer over 'optparse'.
# See: https://github.com/ManageIq/trollop and http://trollop.rubyforge.org/
require 'trollop'

require 'json'

require 'eec2/ec2_costs'


# A wrapper class for Aws::EC2, providing some useful extra functionality.
# RubyMine has real problems resolving methods inside the Aws and Aws::EC2::Client classes, so just disable the warning.
# noinspection RubyResolve
class Ec2Wrapper
  # @!attribute [r] ec2
  #   @return [Aws::EC2::Client] the EC2 client object
  attr_accessor :ec2

  # Initialize method.
  #
  # @param [Trollop::Parser] global_parser
  # @param [Hash] options Contains optional :region, :key, and :secret.
  def initialize(global_parser, options)
    Aws.use_bundled_cert!

    aws_options               = {}
    aws_options[:region]      = options[:region] unless options[:region].nil?
    aws_options[:credentials] = Aws::Credentials.new(options[:key], options[:secret]) unless options[:key].nil?
    Aws.config.update aws_options unless aws_options.empty?

    begin
      @aws_dir = "#{Dir.home}/.aws"

      if !File.exists? "#{@aws_dir}/config" and (options[:region].nil? or options[:key].nil? or options[:secret].nil?)
        raise Aws::Errors::MissingRegionError
      end

      # RubyMine gets very confused about the following 'new' call, due (I assume) to multiple 'Client' classes
      # in the AWS SDK. So suppress the warning:
      # noinspection RubyArgCount
      @ec2 = Aws::EC2::Client.new

      # Now that we've successfully initialized ec2, save the config:
      unless File.exists? "#{@aws_dir}/config"
        Dir.mkdir "#{@aws_dir}" unless Dir.exists? "#{@aws_dir}"

        $stderr.puts "Creating #{Dir.home.gsub /\\/, '/'}/.aws/config"
        File.open("#{@aws_dir}/config", 'w') do |f|
          contents = <<-EOS
          [default]
          output = json
          region = #{options[:region]}
          EOS
          f.puts contents.gsub /^ +/, ''
        end

        $stderr.puts "Creating #{Dir.home.gsub /\\/, '/'}/.aws/credentials"
        File.open("#{@aws_dir}/credentials", 'w') do |f|
          contents = <<-EOS
          [default]
          aws_access_key_id = #{options[:key]}
          aws_secret_access_key = #{options[:secret]}
          EOS
          f.puts contents.gsub /^ +/, ''
        end
      end

    rescue Aws::Errors::MissingRegionError, Aws::Errors::MissingCredentialsError
      c1, c2 = '', ''
      c1, c2 = "\e[1;40;33m", "\e[0m" if $stdout.isatty

      # TODO: jafischer-2017-03-19 Should really remove the global_parser parameter, and do this in the calling code:
      $stderr.puts c1
      $stderr.puts "It looks like this is the first time you've run this script."
      $stderr.puts 'As a one-time configuration step: please run it again, specifying the AWS region and'
      $stderr.puts 'credentials (see below for help).'
      $stderr.puts 'Note: if you have not yet created your AWS access key id and secret access key,'
      $stderr.puts 'you can do so here: https://console.aws.amazon.com/iam/home'
      $stderr.puts c2
      global_parser.educate $stderr
      exit 1
    end
  end

  # Retrieves information about one or more EC2 instances.
  #
  # @param names [Array<String>] Optional array of names. Wildcards are supported.
  # @return [Array<Hash>, int] Array of hashes containing pertinent information about the instances, and the
  # width of the longest instance name (useful for formatting output).
  def get_instance_info(names = [])
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
          name:           '<unnamed>',
          id:             instance.instance_id,
          state:          instance.state.name,
          state_code:     instance.state.code,
          launch_time:    instance.launch_time,
          public_ip:      instance.public_ip_address.nil? ? '<n/a>' : instance.public_ip_address,
          private_ip:     instance.private_ip_address.nil? ? '<n/a>' : instance.private_ip_address,
          login_user:     'ec2-user',
          type:           instance.instance_type,
          region:         instance.placement.availability_zone,
          tenancy:        instance.placement.tenancy,
          key:            instance.key_name,
          key_path:       "#{Dir.home}/.ssh/#{instance.key_name}.pem",
          net_interfaces: instance.network_interfaces,
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


  # Uses the Amazon EC2 price list to determine the running cost of the specified instance.
  #
  # @param [Hash] instance_info A single instance_info entry from the array returned by {#get_instance_info}.
  # @return [float] Instance price.
  def get_instance_cost(instance_info)
    cost = Ec2Costs.lookup(
      # Convert availability zone to region name, e.g. 'us-east-1e' -> 'us-east-1'
      instance_info[:region].sub(/[a-z]$/, ''),
      instance_info[:type])
    return cost unless cost.nil?

    $stderr.puts "WARNING: no price data found for instance type #{instance_info[:type]}"
    0.0
  end


  # Uses the (confusingly-named) run_instances API to create and launch one or more instances. Also sets the 'Name' tag.
  #
  # @param [Array<String>] names names of the instances you want to create
  # @param [Hash] options instance creation options: image_id (the AMI id), key_name, security_group_ids, instance_type, and subnet_id.
  def create_instances(names, options)
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
    instance_infos.each {|i| instance_ids.push i[:id]; puts i[:name]}
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


  def add_tag(names, tag, value)
    instance_infos, _ = get_instance_info names
    instance_infos.each do |i|
      @ec2.create_tags({
                         resources: [i[:id]],
                         tags:      [{ key: tag, value: value }]
                       })
    end
  end
end
