#!/bin/bash
while true
do
bash /home/pi/Documents/git/BaTbot/bin/batbot.sh
echo "¡The bot is crashed!"
echo "Rebooting in:"
for i in 1
do
echo "$i..."
done
echo "###########################################"
echo "# ActionLauncherBot is restarting now     #"
echo "###########################################"
done
