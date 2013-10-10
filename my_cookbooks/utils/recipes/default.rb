# Install monitoring tools
package 'htop'
package 'dstat'
package 'sysstat'

# More awesome than screen
package 'tmux'

# Install MongoDB plugin for dstat
execute "wget -P /usr/share/dstat/ https://raw.github.com/gianpaj/dstat/master/plugins/dstat_mongodb_cmds.py"

# Install MongoHacker
execute [
  'wget -P /tmp https://github.com/TylerBrock/mongo-hacker/archive/master.zip',
  'unzip /tmp/master.zip -d /tmp/',
  'cd /tmp/mongo-hacker-master',
  'make',
  'ln mongo_hacker.js /home/ec2-user/.mongorc.js',
  'chown ec2-user:    /home/ec2-user/.mongorc.js',
  'rm -rf /tmp/{mongo-hacker-master,master.zip}'
].join(' && ')
