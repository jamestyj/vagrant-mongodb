Vagrant.configure('2') do |config|

  require_relative 'libs/aws/amis'

  config.vm.box     = 'dummy'
  config.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

  # Omnibus always installs Chef even if it is already there. Thus disable it
  # by default for 'vagrant provision' run without needlessly re-installing it.
  if ENV['VAGRANT_OMNIBUS']
    config.omnibus.chef_version = :latest
  end

  # Workaround for "sudo: sorry, you must have a tty to run sudo" error. See
  # https://github.com/mitchellh/vagrant/issues/1482 for details.
  config.ssh.pty = true

  config.vm.provider :aws do |aws, override|
    # Workaround for "~/aws/keys/#{aws.region}/#{ENV['USER']}.pem", which for
    # some reason expands to an object instead of a string. E.g. the following
    # fails:
    #
    #   override.ssh.private_key_path = ENV['VAGRANT_SSH_PRIVATE_KEY_PATH'] ||
    #                                   "~/aws/keys/#{aws.region}/#{ENV['USER']}.pem"
    #
    aws_region            = ENV['VAGRANT_AWS_REGION']        || 'eu-west-1'
    aws.region            = aws_region

    aws.keypair_name      = ENV['VAGRANT_AWS_KEYPAIR_NAME']  || ENV['USER']

    # See http://aws.amazon.com/ec2/instance-types/ for list of Amazon EC2
    # instance types.
    aws.instance_type     = ENV['VAGRANT_AWS_INSTANCE_TYPE'] || 'm1.medium'

    # Tag the EC2 instance for easier management and clean-up, especially on
    # shared accounts.
    aws.tags = {
      'Name'      => ENV['VAGRANT_AWS_TAG_NAME']   || 'MongoDB (started by vagrant-mongodb)',
      'owner'     => ENV['VAGRANT_AWS_TAG_OWNER']  || ENV['USER'],
      'expire-on' => ENV['VAGRANT_AWS_TAG_EXPIRE'] || (Date.today + 30).to_s
    }

    # See http://aws.amazon.com/ec2/instance-types/#instance-details for the
    # instance types that support this.
    aws.ebs_optimized     = false

    # TODO Auto-create the 'MongoDB' security group, or at least document
    # manual steps. Inbound ports on 22 (SSH) and 27017 (MongoDB) should be
    # allowed.
    aws.security_groups = [ 'MongoDB' ]

    aws_amis(aws)

    override.ssh.username         = 'ec2-user'
    override.ssh.private_key_path = ENV['VAGRANT_SSH_PRIVATE_KEY_PATH'] ||
                                    "~/aws/keys/#{aws_region}/#{ENV['USER']}.pem"
  end

  def provision_chef_solo_base(chef)
    chef.add_recipe 'chef-solo-search'

    unless ENV['VAGRANT_MINIMAL']
      chef.add_recipe 'utils'
      chef.add_recipe 'mosh'
    end

    chef.cookbooks_path = ['cookbooks', 'my_cookbooks']
    chef.data_bags_path = 'data_bags'

    chef.json = {
      mongodb: {
        cluster_name: 'cluster1',
        port:         27017
      }
    }
  end

  def provision_chef_solo_mongod(chef)
    provision_chef_solo_base(chef)

    chef.add_recipe 'ebs' unless ENV['VAGRANT_MINIMAL']
    chef.add_recipe 'mongodb'

    # Don't include on the first run, as we need to get and distribute the hostnames first.
    chef.add_recipe 'mongodb::replicaset' unless ENV['VAGRANT_FIRST_RUN']

    chef.json[:mongodb][:replicaset_name] = 'rs1'
    chef.json[:mongodb][:shard_name]      = 'rs1'
    chef.json[:mongodb][:dbpath]          = '/data'
    chef.json[:mongodb][:smallfiles]      = true

    unless ENV['VAGRANT_MINIMAL']
      chef.json[:ebs] = {
        access_key: ENV['AWS_ACCESS_KEY'],
        secret_key: ENV['AWS_SECRET_KEY']
      }
      chef.json[:ebs][:volumes] = {
        '/data' => {
          size:          20,
          fstype:        'ext4',
          mount_options: 'noatime,noexec'
        }
      }
    end
  end

  # mongod
  for i in 1..3
    config.vm.define "mongodb-rs1-#{i}" do |mongod|
      mongod.vm.provision :chef_solo do |mongod_chef|
        provision_chef_solo_mongod(mongod_chef)
      end
    end
  end

  # config server
  config.vm.define "mongodb-cfg-1" do |configsvr|
    configsvr.vm.provision :chef_solo do |configsvr_chef|
      provision_chef_solo_base(configsvr_chef)
      configsvr_chef.add_recipe 'mongodb::configserver' unless ENV['VAGRANT_FIRST_RUN']
      configsvr_chef.json[:mongodb][:dbpath]     = '/data/configdb'
      configsvr_chef.json[:mongodb][:port]       = 27019
      configsvr_chef.json[:mongodb][:smallfiles] = true
    end
  end

  # mongos
  config.vm.define "mongodb-mongos-1" do |mongos|
    mongos.vm.provision :chef_solo do |mongos_chef|
      provision_chef_solo_base(mongos_chef)
      mongos_chef.add_recipe 'mongodb::mongos' unless ENV['VAGRANT_FIRST_RUN']
    end
  end
end