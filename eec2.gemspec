Gem::Specification.new do |s|
  s.name        = 'eec2'
  s.version     = '1.0.3'
  s.date        = '2017-03-11'
  s.summary     = 'Enhanced EC2 commands'
  s.description = 'A set of convenient commands for working with EC2 instances, using their Name tag rather than instance id'
  s.authors     = ['Jonathan Fischer']
  s.email       = 'eec2gem@gmail.com'
  s.files       = %w(
                  bin/eec2
                  bin/eec2.cmd
                  lib/eec2/cacert.pem
                  lib/eec2/create_command.rb
                  lib/eec2/delete_command.rb
                  lib/eec2/ec2_wrapper.rb
                  lib/eec2/global_command_wrapper.rb
                  lib/eec2/list_command.rb
                  lib/eec2/ren_command.rb
                  lib/eec2/scp_command.rb
                  lib/eec2/ssh_command.rb
                  lib/eec2/start_command.rb
                  lib/eec2/stop_command.rb
                  lib/eec2/sub_command.rb
                  )
  s.executables << 'eec2'
  s.homepage = 'http://rubygems.org/gems/eec2'
  s.license  = 'MIT'

  s.add_dependency('trollop', ['~> 2.0'])
  s.add_dependency('aws-sdk', ['~> 2.3'])

end
