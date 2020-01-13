# ~/.bash_logout: executed by bash(1) when login shell exits.

# when leaving the console clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi


if ! diff /etc/passwd /etc-backup/passwd &> /dev/null; then
  echo "WARNING - you edited users without backing up the configuration.\
  We will attempt to persist these at container exit, but you may run the command\
  backup-users at any time to do so manually."
fi
