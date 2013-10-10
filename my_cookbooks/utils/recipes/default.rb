# Install monitoring tools
package 'htop'
package 'dstat'
package 'sysstat'

# More awesome than screen
package 'tmux'

# Install MongoDB plugin for dstat
execute "wget -P /usr/share/dstat/ https://raw.github.com/gianpaj/dstat/master/plugins/dstat_mongodb_cmds.py"
