#!/bin/sh

set -eu

SSHPATH="$HOME/.ssh"

if [ ! -d "$SSHPATH" ]
then
  mkdir "$SSHPATH"
fi

if [ ! -f "$SSHPATH/known_hosts" ]
then
  touch "$SSHPATH/known_hosts"
fi

echo "$INPUT_KEY" > "$SSHPATH/deploy_key"

chmod 700 "$SSHPATH"
chmod 600 "$SSHPATH/known_hosts"
chmod 600 "$SSHPATH/deploy_key"

eval $(ssh-agent)

ssh-add "$SSHPATH/deploy_key"

echo ""
echo '##[command]Commands'

echo '#!/bin/bash' >> $HOME/shell.sh

echo 'echo ""' >> $HOME/shell.sh

IFS='
'
for i in $INPUT_COMMAND
do
    echo $i
    echo 'COMMAND=$(cat <<-END' >> $HOME/shell.sh
    echo $i >> $HOME/shell.sh
    echo 'END' >> $HOME/shell.sh
    echo ')' >> $HOME/shell.sh
    echo 'echo "##[command]"$COMMAND' >> $HOME/shell.sh
    echo $i >> $HOME/shell.sh
    echo 'echo ""' >> $HOME/shell.sh
done

echo ""
echo '##[command]Run commands'

if [ "$INPUT_PASS" = "" ]
then
  sh -c "ssh -A -i $SSHPATH/deploy_key -o StrictHostKeyChecking=no -p $INPUT_PORT ${INPUT_USER}@${INPUT_HOST} < $HOME/shell.sh"
else
  sh -c "sshpass -A -p $INPUT_PASS ssh -o StrictHostKeyChecking=no -p $INPUT_PORT ${INPUT_USER}@${INPUT_HOST} < $HOME/shell.sh"
fi
