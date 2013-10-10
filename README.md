vagrant-mongodb
===============

Our goal is to simplify the creation of MongoDB instances for testing and
development.

http://www.vagrantup.com/

http://www.opscode.com/chef/

http://berkshelf.com/


http://aws.amazon.com/ec2/

    gem install berkshelf
    berks install -p cookbooks

    VAGRANT_DEBUG=1
    vagrant up --provider=aws --no-provision --no-parallel && sleep 30 && vagrant provision && vagrant ssh

    vagrant destroy -f


  ```
  An error occurred while executing multiple actions in parallel.
  Any errors that occurred are shown below.

  An error occurred while executing the action on the 'default'
  machine. Please handle this error then try again:

  The following SSH command responded with a non-zero exit status.
  Vagrant assumes that this means the command failed!

  mkdir -p '/tmp/vagrant-chef-1/chef-solo-1/cookbooks'

  Stdout from the command:



  Stderr from the command:

  sudo: sorry, you must have a tty to run sudo
  ```
