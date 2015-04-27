# Install monitoring tools
package 'dstat'
package 'htop'
package 'sysstat'

# Install other useful utils
package 'git'
package 'tmux'
package 'tree'

execute 'install_mongo_hacker' do
  command [
    'git clone https://github.com/TylerBrock/mongo-hacker.git',
    'cd mongo-hacker',
    'make install'
  ].join(' && ')
end

execute 'clean_up_vagrant_omnibus' do
  command 'rm -f /home/centos/install.sh'
end

cookbook_file 'public_ip' do
  path  '/home/centos/public_ip'
  owner 'centos'
  group 'centos'
  mode  '0755'
end
