Vagrant.configure('2') do |config|
  config.vm.box     = 'dummy'
  config.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

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
    aws.instance_type     = ENV['VAGRANT_AWS_INSTANCE_TYPE'] || 't1.micro'

    # TODO Auto-create the 'MongoDB' security group, or at least document
    # manual steps. Inbound ports on 22 (SSH) and 27017 (MongoDB) should be
    # allowed.
    aws.security_groups = [ 'MongoDB' ]

    # TODO Add the corresponding AMIs for other regions
    aws.region_config 'eu-west-1', :ami => 'ami-149f7863'

    # Workaround for https://github.com/mitchellh/vagrant/issues/1482.
    aws.user_data = File.read 'user_data.txt'

    override.ssh.username         = 'ec2-user'
    override.ssh.private_key_path = ENV['VAGRANT_SSH_PRIVATE_KEY_PATH'] ||
                                    "~/aws/keys/#{aws_region}/#{ENV['USER']}.pem"

    # Disable rsynced folders to avoid the "sudo: sorry, you must have a tty to
    # run sudo" error. See https://github.com/mitchellh/vagrant/issues/1482 for
    # details. Note that even though we have the workaround in user_data.txt,
    # the initial run when doing `vagrant up` is still going to fail because
    # it's still using an existing SSH connection.
    config.vm.synced_folder '.', '/vagrant', :disabled => true
  end

  config.vm.provision 'chef_solo' do |chef|
    chef.add_recipe 'mongodb'
  end
end
