# vagrant-mongodb

The goal of this project is to simplify the creation of MongoDB instances for
testing and development. It currently relies on [Amazon EC2]
(http://aws.amazon.com/ec2/), but since it's based on [Vagrant]
(http://www.vagrantup.com/) which supports various backends, it can be extended
to work on other platforms (eg. VirtualBox, VMWare, OpenStack, KVM, LXC).

Once the instance is up and running, [Chef](http://www.opscode.com/chef/) takes
over to set things up. Vagrant is agnostic to the configuration management
framework, so the Chef configuration can be replaced with alternatives like
[Puppet](http://puppetlabs.com/puppet/puppet-open-source).


## 1  Quickstart

Once you have the initial configuration done (details in later sections),
spinning up a new fully configured MongoDB instance in EC2 from scratch takes
about 5 mins.

  * To start an instance with the defaults, just run `./up` (script '[up]
    (up)').  This starts a new instance, installs, configures, and then SSHs
    into it. It does the following by default:

    * Starts a new `m1.medium` 64-bit Amazon Linux instance from the standard
      AMI released by Amazon.

    * Creates a 20 GB RAID 10 EXT4 volume from x4 10 GB EBS volumes. It's
      mounted on `/data` with `noatime,noexec` and a block size of 32 sectors
      (16 KB).

    * The latest stable version of MongoDB is installed from the MongoDB, Inc.
      (formerly 10gen) repositories. It is configured with `dbpath=/data` and
      `smallfiles=true` (to speed up initial journal preallocation).

    * Performance monitoring tools `htop`, `dstat`, and `sysstat` (which
      provides `iostat`) are installed. The [MongoDB plugin for dstat]
      (https://github.com/gianpaj/dstat) is also installed.

    * Productivity tools like [MongoHacker]
      (https://github.com/TylerBrock/mongo-hacker), [tmux]
      (http://tmux.sourceforge.net/), and [Mosh] (http://mosh.mit.edu/) are
      also installed.

  * Once you're done, run `./down` (script '[down] (down)') to terminate the
    instance. Note that you'll need to remove the EBS volumes on your own.


## 2  Configuration

### 2.1  Initial setup

  1. [Download and install Vagrant](http://www.vagrantup.com/downloads). Use
     the latest stable release (e.g. version 1.4 and above).

  1. Install the required Vagrant plugins by running:

     ```bash
     vagrant plugin install vagrant-aws
     vagrant plugin install vagrant-omnibus
     ```

  1. Install [Berkshelf](http://berkshelf.com/). If you already have Ruby
     installed (which you should), simply run:

     ```bash
     sudo gem install berkshelf
     ```

  1. Add your AWS access and secret keys as environment variables by adding the
     following to your `~/.bash_profile` or `~/.bashrc`. If you've used the AWS
     command line tools before, this should already be there.

     ```bash
     export AWS_ACCESS_KEY=ABCDEFGHIJKLMNOPQRST
     export AWS_SECRET_KEY=1234567890abcedefgijklmnopqrstuvwxyzABCD
     ```

  1. The script expects your AWS EC2 keypair private key to be in the following
     location: `~/aws/keys/#{aws.region}/#{ENV['USER']}.pem`. For example, if
     your local login user is `jamestyj` and you're using the default EC2
     region `eu-west-1`, it will use the private key at
     `~/aws/keys/eu-west-1/jamestyj.pem`. You can override this with the
     environment variable `VAGRANT_SSH_PRIVATE_KEY_PATH`.

  1. Create an EC2 security group (firewall rule) named 'MongoDB'. It must
     allow incoming traffic on TCP ports 22 (SSH) and 27017 (MongoDB). We also
     recommend opening UDP ports 60000 to 60010 for Mosh (SSH replacement).

### 2.2  Vagrant config

#### 2.2.1 Environment variables

There are a number of commonly used options that can be altered via environment
variables. You can refer to the Vagrant configuration file ([Vagrantfile]
(Vagrantfile)) for details. Here's a list of available environment variables:

  1. `VAGRANT_AWS_REGION` - AWS region to start the EC2 instance in. Defaults
     to `eu-west-1`.

  1. `VAGRANT_AWS_KEYPAIR_NAME` - EC2 keypair name, which should match an
     existing keypair. You need one per region and can create them via the AWS
     web UI if you don't already have one.

  1. `VAGRANT_AWS_INSTANCE_TYPE` - EC2 instance type. Defaults to `m1.medium`.

  1. `VAGRANT_SSH_PRIVATE_KEY_PATH` - EC2 SSH private key path. Defaults to
     `~/aws/keys/#{aws_region}/#{ENV['USER']}.pem`.

  1. `VAGRANT_DEBUG` - Set Chef log level to `:debug`. Defaults to false
     (`:info`).

  1. `VAGRANT_EBS_RAID` - Use additional EBS volumes to create a RAID volume.
     Defaults to RAID 10 (if enabled at all).

  1. `VAGRANT_AWS_TAG_NAME` - EC2 instance tag `Name`. Defaults to "MongoDB
     instance (launched by vagrant-mongodb)".

  1. `VAGRANT_AWS_TAG_OWNER` - EC2 instance tag `owner`. Defaults to current
     user.

  1. `VAGRANT_AWS_TAG_EXPIRE` - EC2 instance tag `expire-on`, in `YYYY-MM-DD`
     format. Defaults to 30 days from now. No effect on its own, but can be
     used by clean-up scripts.

#### 2.2.2 Modifying the Vagrant config file

Modifying [Vagrantfile] (Vagrantfile) directly gives you more control over your
instance. Details can be found in the Vagrant documentation, but here are some
interesting ones:

  1. `config.vm.provider :aws` section.

     This section contains all the AWS specific configuration, which you can
     modify accordingly to suit your needs and preferences. In particular, you
     may want to add the AMI ID of the Amazon Linux AMI (latest 64 bit, EBS
     backed) for your region if it's not already there. Other than that,
     there's probably not much else you want to change here.

  1. `config.vm.provision :chef_solo` section.

     This section contains all the Chef (Solo) configuration used to setup the
     EC2 instance from the plain Amazon Linux state. It installs a number of
     utilities and tools (from the `utils` and `mosh` cookbooks/recipes), as
     well has handling the EBS volume configuration and MongoDB installation
     plus configuration.

     Most of the interesting options are under the `chef.json` JSON
     configuration, in particular the MongoDB specific ones eg.:

     ```ruby
     :mongodb => {
       :dbpath     => '/data',
       :smallfiles => true      # For faster initial journal preallocation
     }
     ```

     And EBS specific ones:

     ```ruby
     :ebs => {
       ...,
       :fstype           => 'ext4',
       :md_read_ahead    => 32,  # 16KB
       :mdadm_chunk_size => 256
     }
     ```

     As well as the EBS RAID, with provisioned IOPS (`piops`) and LVM disabled
     by default:

     ```ruby
     '/dev/md0' => {
       :num_disks     => 4,
       :disk_size     => 10,                # Size in GB
       :raid_level    => 10,
       :mount_point   => '/data',
       :mount_options => 'noatime,noexec',
       # :piops       => 2000,              # Provisioned IOPS
       # :uselvm      => true
     }
     ```

    You can add more recipes by appending `chef.add_recipe 'xxx'` statements
    and modifying `Berksfile` accordingly.

     Refer to the Chef EBS cookbook documentation for more details and options.


### 2.3  Chef config

We use Chef Solo to setup and configure the EC2 instance from scratch. This
allows full flexibility and transparency at the expense of spin up time, which
typically takes about 5 minutes so isn't really a problem.

#### 2.3.1 Berksfile

Berkshelf is used to manage Chef cookbooks and dependencies. See [Berksfile]
(Berksfile) for the list of Chef cookbooks that are pulled from the OpsCode
cookbooks repository, or directly from the specified Git repositories.

We use Berkshelf to download latest version of the cookbooks (or a specific
version if a version string is given) with the following commands:

```bash
rm -f Berksfile.lock
berks install -p cookbooks/
```

Note that everything under `cookbooks/` will be removed and replaced with the
specified cookbooks.

#### 2.3.2 Chef cookbooks and recipes

The [my_cookbooks] (my_cookbooks/) directory contains cookbooks (eg. utils)
that are specific to this project, so we keep them in this Git tree to keep
things simple. Will likely split this out to a separate Git repository in
future.


## 3  Known issues

  1. The Amazon EBS volumes are not deleted when the EC2 instance is
     terminated, so you'll need to do this manually. The enhancement request is
     tracked in [Github Issues]
     (https://github.com/jamestyj/vagrant-mongodb/issues/1).

## 4 Contributions and feedback

Code and documentation contributions in the form of pull requests are very
welcomed! Please file feature requests and bugs reports via Github Issues.

## 5  Sample run output

```
jamestyj@Jamess-MacBook-Air:vagrant-mongodb(master)> ./up
Using aws (0.101.6)
Using delayed_evaluator (0.2.0)
Installing ebs (0.3.6) from git: 'git://github.com/jamestyj/chef-ebs.git' with branch: 'master' at ref: 'd8db80483b65a8e04c33e8d5aeeb5eb8f058c1e8'
Installing mongodb (0.13.2) from git: 'git://github.com/edelight/chef-mongodb.git' with branch: 'master' at ref: 'baf6130fcebd3674ed67c601214addbcd167bb45'
Installing mosh (0.3.0) from git: 'git://github.com/jtimberman/mosh-cookbook' with branch: 'master' at ref: '36d71e960be7be16031ae7352261be40a17e0d98'
Using yum (2.3.4)
Using apt (2.2.0)
Bringing machine 'default' up with 'aws' provider...
[default] Warning! The AWS provider doesn't support any of the Vagrant
high-level network configurations (`config.vm.network`). They
will be silently ignored.
[default] Launching an instance with the following settings...
[default]  -- Type: m1.medium
[default]  -- AMI: ami-149f7863
[default]  -- Region: eu-west-1
[default]  -- Keypair: jamestyj
[default]  -- Security Groups: ["MongoDB"]
[default]  -- Block Device Mapping: []
[default]  -- Terminate On Shutdown: false
[default] Waiting for instance to become "ready"...
[default] Waiting for SSH to become available...
[default] Machine is booted and ready for use!
[default] Rsyncing folder: /Users/jamestyj/code/vagrant-mongodb-rs1/cookbooks/ => /tmp/vagrant-chef-1/chef-solo-1/cookbooks
[default] Rsyncing folder: /Users/jamestyj/code/vagrant-mongodb-rs1/my_cookbooks/ => /tmp/vagrant-chef-1/chef-solo-2/cookbooks
[default] Rsyncing folder: /Users/jamestyj/code/vagrant-mongodb-rs1/cookbooks/ => /tmp/vagrant-chef-1/chef-solo-1/cookbooks
[default] Rsyncing folder: /Users/jamestyj/code/vagrant-mongodb-rs1/my_cookbooks/ => /tmp/vagrant-chef-1/chef-solo-2/cookbooks
[default] Running provisioner: chef_solo...
Generating chef JSON and uploading...
Running chef-solo...
[2013-10-11T15:04:35+00:00] INFO: Forking chef instance to converge...
[2013-10-11T15:04:35+00:00] INFO: *** Chef 11.6.2 ***
[2013-10-11T15:04:36+00:00] INFO: Setting the run_list to ["recipe[utils]", "recipe[mosh]", "recipe[ebs]", "recipe[mongodb::10gen_repo]", "recipe[mongodb]"] from JSON
[2013-10-11T15:04:36+00:00] INFO: Run List is [recipe[utils], recipe[mosh], recipe[ebs], recipe[mongodb::10gen_repo], recipe[mongodb]]
[2013-10-11T15:04:36+00:00] INFO: Run List expands to [utils, mosh, ebs, mongodb::10gen_repo, mongodb]
[2013-10-11T15:04:36+00:00] INFO: Starting Chef Run for ip-172-31-36-221.eu-west-1.compute.internal
[2013-10-11T15:04:36+00:00] INFO: Running start handlers
[2013-10-11T15:04:36+00:00] INFO: Start handlers complete.
[2013-10-11T15:04:48+00:00] INFO: New RightAws::Ec2 using shared connections mode
[2013-10-11T15:04:48+00:00] INFO: Opening new HTTPS connection to eu-west-1.ec2.amazonaws.com:443
[2013-10-11T15:04:52+00:00] INFO: Volume vol-a61565f3 is available
[2013-10-11T15:04:59+00:00] INFO: Volume vol-a61565f3 is attached to i-97a26cd8
[2013-10-11T15:04:59+00:00] WARN: Cloning resource attributes for directory[/data] from prior resource (CHEF-3694)
[2013-10-11T15:04:59+00:00] WARN: Previous directory[/data]: /tmp/vagrant-chef-1/chef-solo-1/cookbooks/ebs/recipes/volumes.rb:56:in `block in from_file'
[2013-10-11T15:04:59+00:00] WARN: Current  directory[/data]: /tmp/vagrant-chef-1/chef-solo-1/cookbooks/mongodb/definitions/mongodb.rb:124:in `block in from_file'
[2013-10-11T15:05:01+00:00] INFO: package[htop] installing htop-1.0.1-2.3.amzn1 from amzn-main repository
[2013-10-11T15:05:04+00:00] INFO: package[dstat] installing dstat-0.7.0-1.5.amzn1 from amzn-main repository
[2013-10-11T15:05:07+00:00] INFO: package[sysstat] installing sysstat-9.0.4-20.8.amzn1 from amzn-main repository
[2013-10-11T15:05:10+00:00] INFO: package[tmux] installing tmux-1.8-2.5.amzn1 from amzn-main repository
[2013-10-11T15:05:13+00:00] INFO: execute[wget -P /usr/share/dstat/ https://raw.github.com/gianpaj/dstat/master/plugins/dstat_mongodb_cmds.py] ran successfully
[2013-10-11T15:05:14+00:00] INFO: execute[wget -P /tmp https://github.com/TylerBrock/mongo-hacker/archive/master.zip && unzip /tmp/master.zip -d /tmp/ && cd /tmp/mongo-hacker-master && make && ln mongo_hacker.js /home/ec2-user/.mongorc.js && chown ec2-user:    /home/ec2-user/.mongorc.js && rm -rf /tmp/{mongo-hacker-master,master.zip}] ran successfully
[2013-10-11T15:05:14+00:00] INFO: Updating epel repository in /etc/yum.repos.d/epel.repo (setting enabled=1)
[2013-10-11T15:05:14+00:00] INFO: template[/etc/yum.repos.d/epel.repo] backed up to /var/chef/backup/etc/yum.repos.d/epel.repo.chef-20131011150514
[2013-10-11T15:05:14+00:00] INFO: template[/etc/yum.repos.d/epel.repo] updated file contents /etc/yum.repos.d/epel.repo
[2013-10-11T15:05:14+00:00] INFO: template[/etc/yum.repos.d/epel.repo] sending run action to execute[yum-makecache-epel] (immediate)
[2013-10-11T15:05:21+00:00] INFO: execute[yum-makecache-epel] ran successfully
[2013-10-11T15:05:21+00:00] INFO: template[/etc/yum.repos.d/epel.repo] sending create action to ruby_block[reload-internal-yum-cache-for-epel] (immediate)
[2013-10-11T15:05:21+00:00] INFO: ruby_block[reload-internal-yum-cache-for-epel] called
[2013-10-11T15:05:24+00:00] INFO: package[mosh] installing mosh-1.2.4-1.el6 from epel repository
[2013-10-11T15:05:28+00:00] INFO: device /dev/xvdg ready
[2013-10-11T15:05:38+00:00] INFO: execute[mkfs] ran successfully
[2013-10-11T15:05:38+00:00] INFO: directory[/data] created directory /data
[2013-10-11T15:05:38+00:00] INFO: directory[/data] mode changed to 755
[2013-10-11T15:05:39+00:00] INFO: mount[/data] mounted
[2013-10-11T15:05:39+00:00] INFO: mount[/data] enabled
[2013-10-11T15:05:39+00:00] INFO: Adding 10gen repository to /etc/yum.repos.d/10gen.repo
[2013-10-11T15:05:39+00:00] INFO: template[/etc/yum.repos.d/10gen.repo] created file /etc/yum.repos.d/10gen.repo
[2013-10-11T15:05:39+00:00] INFO: template[/etc/yum.repos.d/10gen.repo] updated file contents /etc/yum.repos.d/10gen.repo
[2013-10-11T15:05:39+00:00] INFO: template[/etc/yum.repos.d/10gen.repo] mode changed to 644
[2013-10-11T15:05:39+00:00] INFO: template[/etc/yum.repos.d/10gen.repo] sending run action to execute[yum-makecache-10gen] (immediate)
[2013-10-11T15:05:40+00:00] INFO: execute[yum-makecache-10gen] ran successfully
[2013-10-11T15:05:40+00:00] INFO: template[/etc/yum.repos.d/10gen.repo] sending create action to ruby_block[reload-internal-yum-cache-for-10gen] (immediate)
[2013-10-11T15:05:40+00:00] INFO: ruby_block[reload-internal-yum-cache-for-10gen] called
[2013-10-11T15:05:43+00:00] INFO: package[mongo-10gen-server] installing mongo-10gen-server-2.4.6-mongodb_1 from 10gen repository
[2013-10-11T15:06:00+00:00] INFO: template[/etc/sysconfig/mongod] backed up to /var/chef/backup/etc/sysconfig/mongod.chef-20131011150600
[2013-10-11T15:06:00+00:00] INFO: template[/etc/sysconfig/mongod] updated file contents /etc/sysconfig/mongod
[2013-10-11T15:06:00+00:00] INFO: directory[/var/log/mongodb] created directory /var/log/mongodb
[2013-10-11T15:06:00+00:00] INFO: directory[/var/log/mongodb] owner changed to 220
[2013-10-11T15:06:00+00:00] INFO: directory[/var/log/mongodb] group changed to 498
[2013-10-11T15:06:00+00:00] INFO: directory[/var/log/mongodb] mode changed to 755
[2013-10-11T15:06:00+00:00] INFO: directory[/data] owner changed to 220
[2013-10-11T15:06:00+00:00] INFO: directory[/data] group changed to 498
[2013-10-11T15:06:00+00:00] INFO: template[/etc/init.d/mongod] backed up to /var/chef/backup/etc/init.d/mongod.chef-20131011150600
[2013-10-11T15:06:00+00:00] INFO: template[/etc/init.d/mongod] updated file contents /etc/init.d/mongod
[2013-10-11T15:06:00+00:00] INFO: template[/etc/init.d/mongod] not queuing delayed action restart on service[mongod] (delayed), as it's already been queued
[2013-10-11T15:06:25+00:00] INFO: service[mongod] started
[2013-10-11T15:06:25+00:00] INFO: template[/etc/sysconfig/mongod] sending restart action to service[mongod] (delayed)
[2013-10-11T15:06:26+00:00] INFO: service[mongod] restarted
[2013-10-11T15:06:26+00:00] INFO: Chef Run complete in 109.229518498 seconds
[2013-10-11T15:06:26+00:00] INFO: Running report handlers
[2013-10-11T15:06:26+00:00] INFO: Report handlers complete

       __|  __|_  )
       _|  (     /   Amazon Linux AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-ami/2013.09-release-notes/
[ec2-user@ip-172-31-36-221 ~]$
```
