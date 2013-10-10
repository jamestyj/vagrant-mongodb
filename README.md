vagrant-mongodb
===============

    gem install berkshelf
    berks install -p cookbooks

    VAGRANT_DEBUG=1
    vagrant up --provider=aws --no-provision && sleep 30 && vagrant provision && vagrant ssh

    vagrant destroy -f
