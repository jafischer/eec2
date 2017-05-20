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
  def initialize(options)
    Aws.use_bundled_cert!

    Aws.config.update(region: options[:region]) unless options[:region].nil?

    # RubyMine gets very confused about the following 'new' call, due (I assume) to multiple 'Client' classes
    # in the AWS SDK. So suppress the warning:
    # noinspection RubyArgCount
    @ec2 = Aws::EC2::Client.new
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

    resp = if names.empty?
             @ec2.describe_instances
           else
             @ec2.describe_instances(filters: [{ name: 'tag:Name', values: names }])
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

        case instance_info[:state_code] & ~256
          when 0 # pending
            instance_info[:colorized_state] = degraded ? (instance_info[:state] + '*').bg_red.bold.brown : instance_info[:state].bold.brown
          when 16 # running
            instance_info[:colorized_state] = degraded ? (instance_info[:state] + '*').bg_red.bold.green : instance_info[:state].bold.green
          when 32 # shutting-down
            instance_info[:colorized_state] = instance_info[:state].bg_gray.red
          when 48 # terminated
            instance_info[:colorized_state] = instance_info[:state].bg_gray.black
          when 64 # stopping
            instance_info[:colorized_state] = instance_info[:state].red
          when 80 # stopped
            instance_info[:colorized_state] = instance_info[:state].bold.red
          else # unknown
            instance_info[:colorized_state] = degraded ? (instance_info[:state] + '*').bg_red.magenta : instance_info[:state].magenta
        end

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


  def add_tag(names, tag, value)
    instance_infos, _ = get_instance_info names
    instance_infos.each do |i|
      @ec2.create_tags({
                         resources: [i[:id]],
                         tags:      [{ key: tag, value: value }]
                       })
    end
  end

  def regions
    %w[
      ap-northeast-1
      ap-northeast-2
      ap-south-1
      ap-southeast-1
      ap-southeast-2
      ca-central-1
      eu-central-1
      eu-west-1
      eu-west-2
      sa-east-1
      us-east-1
      us-east-2
      us-west-1
      us-west-2
    ]
  end
end
