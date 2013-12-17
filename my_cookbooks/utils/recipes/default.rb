# Install monitoring tools
package 'dstat'
package 'htop'
package 'sysstat'

# Install other useful utils
package 'tmux'
package 'tree'

execute 'install_dstat_with_mongodb_plugin' do
  command 'wget -P /usr/share/dstat/ https://raw.github.com/gianpaj/dstat/master/plugins/dstat_mongodb_cmds.py'
  not_if { FileTest.directory?('/usr/share/dstat/') }
end

execute 'install_mongo_hacker' do
  command [
    'wget -P /tmp https://github.com/TylerBrock/mongo-hacker/archive/master.zip',
    'unzip /tmp/master.zip -d /tmp/',
    'cd /tmp/mongo-hacker-master',
    'make',
    'ln mongo_hacker.js /home/ec2-user/.mongorc.js',
    'chown ec2-user:    /home/ec2-user/.mongorc.js',
    'rm -rf /tmp/{mongo-hacker-master,master.zip}'
  ].join(' && ')
  not_if { ::File.exists?('/home/ec2-user/.mongorc.js') }
end

execute 'clean_up_vagrant_omnibus' do
  command 'rm -f /home/ec2-user/install.sh'
end
