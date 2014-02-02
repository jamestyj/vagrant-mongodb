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

  def mongodb_base_config(chef)
    chef.add_recipe 'chef-solo-search'
    chef.add_recipe 'utils'
    chef.add_recipe 'mosh'
    chef.add_recipe 'ebs'
    chef.add_recipe 'mongodb::10gen_repo'
    chef.add_recipe 'mongodb'

    # Don't include on the first run, as we need to get and distribute the hostnames first.
    if ENV['VAGRANT_REPLICASET']
      chef.add_recipe 'mongodb::replicaset'
    end

    chef.cookbooks_path = ['cookbooks', 'my_cookbooks']
    chef.data_bags_path = 'data_bags'
    chef.json = {
      mongodb: {
        cluster_name:    'rs1',
        shard_name:      'rs1',
        replicaset_name: 'rs1',
        dbpath:          '/data',
        smallfiles:      true
      },
      ebs: {
        access_key: ENV['AWS_ACCESS_KEY'],
        secret_key: ENV['AWS_SECRET_KEY']
      }
    }
    chef.json[:ebs][:volumes] = {
      '/data' => {
        size:          20,
        fstype:        'ext4',
        mount_options: 'noatime,noexec'
      }
    }
  end

  def mongodb_provision(config)
    config.vm.provision :chef_solo do |chef|
      mongodb_base_config(chef)
    end
  end

  for i in 1..3
    config.vm.define "mongodb-rs1-#{i}" do |mongo|
      mongodb_provision(config)
    end
  end
end