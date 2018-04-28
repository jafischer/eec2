# AWS EC2 SDK: see http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html
require 'aws-sdk'
# Trollop: a command-line argument parser that I prefer over 'optparse'.
# See: https://github.com/ManageIq/trollop and http://trollop.rubyforge.org/
require 'trollop'
require 'json'
require 'concurrent'
require 'digest'


# A wrapper class for Aws::EC2, providing some useful extra functionality.
# RubyMine has real problems resolving methods inside the Aws and Aws::EC2::Client classes, so just disable the warning.
# noinspection RubyResolve
class Ec2Wrapper
  # @!attribute [r] ec2
  #   @return [Aws::EC2::Client] the EC2 client object
  attr_accessor :ec2

  # Initialize method.
  #
  # @param [Hash] options Contains optional :region
  def initialize(options)
    @aws_dir = "#{Dir.home}/.aws"

    # The user may have set environment variables for the AWS CLI, so if the ~/.aws files are also present, display a
    # notification.
    if !ENV['AWS_ACCESS_KEY'].nil? and File.exist? "#{@aws_dir}/credentials"
      $stderr.puts 'WARNING: you have the AWS environment variables (e.g. AWS_ACCESS_KEY and others), but you also have a ~/.aws/credentials file.'.brown
      $stderr.puts 'Be aware that the environment variables take precedence.'.brown
    end

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

    # TODO: jafischer-2017-05-26 Get rid of name_width here, and just use .map wherever we
    # need it. E.g.:
    # name_width = instance_infos.map {|i| i[:name].length }.max
    name_width     = 0
    instance_infos = []

    resp.reservations.each do |reservation|
      reservation.instances.each do |instance|
        # Debugging: dump instance info
        # File.open("/Users/Jonathan/.aws/instance_#{instance.instance_id}.yaml", 'w') { |f| f.write instance.to_yaml }

        instance_info = {
          name:           '<unnamed>',
          id:             instance.instance_id,
          state:          instance.state.name,
          state_code:     instance.state.code,
          launch_time:    instance.launch_time,
          public_ip:      instance.public_ip_address.nil? ? '<n/a>' : instance.public_ip_address,
          private_ip:     instance.private_ip_address.nil? ? '<n/a>' : instance.private_ip_address,
          login_user:     nil,
          type:           instance.instance_type,
          region:         instance.placement.availability_zone,
          tenancy:        instance.placement.tenancy,
          key:            instance.key_name,
          key_path:       "#{Dir.home}/.ssh/#{instance.key_name}.pem",
          net_interfaces: instance.network_interfaces,
          ami:            instance.image_id,
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


  def check_login_names(instance_infos)
    # Find any instances that don't have their login_user tag set (and are running).
    unset_instances = instance_infos.select { |i| i[:state] == 'running' && i[:login_user].nil? }

    # Oh and skip any that don't have the key file in ~/.ssh
    unset_instances = unset_instances.select { |u| File.exists? u[:key_path] }

    unless unset_instances.empty?
      $stderr.puts "Note: the following instances do not have the 'login_user' Tag set:".brown
      $stderr.puts ((unset_instances.map { |i| i[:name] }).join ', ').brown
      $stderr.puts 'Attempting to determine the login user automatically...'.brown

      # No need to check any particular AMI more than once, because they will all have the same login user.
      # So lets build a list of unique AMIs
      amis = (unset_instances.map { |i| i[:ami] }).uniq
      $stderr.puts "Unique AMIs: #{amis.join ', '}".brown

      # Now build a list of instances that we'll check (just need one for each AMI)
      ami_instances = amis.map { |ami| (unset_instances.select { |u| u[:state] == 'running' && u[:ami] == ami })[0] }

      $stderr.puts "Instances to ssh to: #{(ami_instances.map { |ai| ai[:name] }).join ' '}".brown

      # Attempt to ssh to each instance using 4 possible login users.
      possible_login_users = %w(ec2-user ubuntu centos root)
      ami_futures          = {}
      ami_instances.each do |i|
        $stderr.puts "Trying the following login users for instance '#{i[:name]}' (AMI #{i[:ami]}): #{possible_login_users.join ', '}".brown
        command = ''
        possible_login_users.each do |login_user|
          command += "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q -i #{i[:key_path]} #{login_user}@#{i[:public_ip]} echo #{login_user} || "
        end
        command              += 'echo unknown'
        ami_futures[i[:ami]] = Concurrent::Future.execute { `#{command}`.chomp }
      end

      # Now wait for async commands to complete (future#value is blocking unless you pass 0 as a parameter)
      ami_futures.each do |ami, future|
        login_user = future.value

        if login_user == 'unknown'
          $stderr.puts "ERROR: Could not determine login user for AMI #{ami}; you will have to set the login_user tag manually.".red.bold
        else
          $stderr.puts "The login user for AMI #{ami} is ".brown + "#{login_user}.".green.bold
          ami_instances = unset_instances.select { |u| u[:ami] == ami }
          $stderr.puts "Updating the following instances: #{ami_instances.map { |i| i[:name] }}".brown
          ami_instances.each { |i| i[:login_user] = login_user }
          @ec2.create_tags({
                             resources: ami_instances.map { |i| i[:id] },
                             tags:      [{ key: 'login_user', value: login_user }]
                           })
        end
      end
    end
  end


  def get_tag(instance_ids, tag_name)
    resp = @ec2.describe_tags({
                                filters: [{
                                            name:   'resource-id',
                                            values: instance_ids
                                          },
                                          {
                                            name:   'tag-key',
                                            values: [tag_name]
                                          }]
                              })
    resp.tags
  end


  def list_tags(names)
    instance_infos, _ = get_instance_info names
    instance_infos.each do |i|
      puts "#{i[:name]}:" if instance_infos.count > 1
      resp = @ec2.describe_tags({
                                  filters: [{
                                              name:   'resource-id',
                                              values: [i[:id]]
                                            }]
                                })
      puts '<No tags are set>' if resp.tags.empty?
      resp.tags.each do |tag|
        puts "    #{tag.key}: #{tag.value}"
      end
    end
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
    %w(
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
    )
  end


  def region_to_display
    {
      'ap-northeast-1' => 'Asia Pacific (Tokyo)',
      'ap-northeast-2' => 'Asia Pacific (Seoul)',
      'ap-south-1'     => 'Asia Pacific (Mumbai)',
      'ap-southeast-1' => 'Asia Pacific (Singapore)',
      'ap-southeast-2' => 'Asia Pacific (Sydney)',
      'ca-central-1'   => 'Canada (Central)',
      'eu-central-1'   => 'EU (Frankfurt)',
      'eu-west-1'      => 'EU (Ireland)',
      'eu-west-2'      => 'EU (London)',
      'sa-east-1'      => 'South America (Sao Paulo)',
      'us-east-1'      => 'US East (N. Virginia)',
      'us-east-2'      => 'US East (Ohio)',
      'us-west-1'      => 'US West (N. California)',
      'us-west-2'      => 'US West (Oregon)',
    }
  end

  def display_to_region
    {
      'Asia Pacific (Tokyo)'      => 'ap-northeast-1',
      'Asia Pacific (Seoul)'      => 'ap-northeast-2',
      'Asia Pacific (Mumbai)'     => 'ap-south-1',
      'Asia Pacific (Singapore)'  => 'ap-southeast-1',
      'Asia Pacific (Sydney)'     => 'ap-southeast-2',
      'Canada (Central)'          => 'ca-central-1',
      'EU (Frankfurt)'            => 'eu-central-1',
      'EU (Ireland)'              => 'eu-west-1',
      'EU (London)'               => 'eu-west-2',
      'South America (Sao Paulo)' => 'sa-east-1',
      'US East (N. Virginia)'     => 'us-east-1',
      'US East (Ohio)'            => 'us-east-2',
      'US West (N. California)'   => 'us-west-1',
      'US West (Oregon)'          => 'us-west-2',
    }
  end

  # Uses the Amazon EC2 price list to determine the running cost of the specified instance.
  #
  # @param [Hash] instance_info A single instance_info entry from the array returned by {#get_instance_info}.
  # @return [float] Instance price.
  def get_instance_cost(instance_info)
    @aws_dir = "#{Dir.home}/.aws"

    # Have we retrieved the price list already?
    if @price_list.nil?
      # Get the pricing list for AmazonEC2
      # See https://aws.amazon.com/about-aws/whats-new/2017/04/use-the-enhanced-aws-price-list-api-to-access-aws-service-and-region-specific-product-and-pricing-information/
      region            = instance_info[:region].sub(/[a-z]$/, '')
      price_list_file   = "#{@aws_dir}/aws_price_list-#{region}.json"
      region_index_file = "#{@aws_dir}/aws_region_index.json"
      region_index_uri  = URI.parse 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonEC2/current/region_index.json'

      # Get the current set of URLs for the various region price lists.
      region_index_resp = Net::HTTP.get_response region_index_uri

      # See if it's changed since the last time we retrieved it.
      current_md5  = Digest::MD5.hexdigest region_index_resp.body
      existing_md5 = File.exists?(region_index_file) ? Digest::MD5.hexdigest(File.read(region_index_file)) : ''
      if current_md5 != existing_md5
        File.open(region_index_file, 'w') { |f| f.write region_index_resp.body }
        # Clean out all old price list files
        Dir.glob("#{@aws_dir}/aws_price_list-*.json").each { |file| File.delete(file)}
      end

      region_index = JSON.parse region_index_resp.body

      # Do we have an up-to-date price list for this instance's region?
      if !File.exists?(price_list_file)
        $stderr.puts "Updating cached AWS price list for region #{region}... please wait."
        uri      = URI.parse "https://pricing.us-east-1.amazonaws.com#{region_index['regions'][region]['currentVersionUrl']}"
        response = Net::HTTP.get_response uri
        raise "Failed to get AWS price list: response code #{response.code}:\n#{response.body}" if response.code.to_i < 200 or response.code.to_i > 299
        File.open(price_list_file, 'w') { |f| f.write response.body }
        @price_list = JSON.parse response.body
      else
        File.open(price_list_file, 'r') { |f| @price_list = JSON.parse(f.read) }
      end
    end

    @price_list['products'].each do |sku, product|
      if product['attributes']['instanceType'] == instance_info[:type]
        if product['attributes']['operatingSystem'] == 'Linux' and
          product['attributes']['preInstalledSw'] == 'NA' and
          product['attributes']['licenseModel'] == 'No License required' and
          (product['attributes']['tenancy'] == instance_info[:tenancy] or
          (product['attributes']['tenancy'] == 'Shared' and instance_info[:tenancy] == 'default'))
          # TODO: Until I can find out how to determine whether an instance is Reserved or On-Demand, we'll use the On-Demand pricing.
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
end
