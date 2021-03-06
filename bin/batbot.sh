#!/bin/bash

# BaTbot versión actual
VERSION="1.4.3.5\nBot de Telegram en Bash - Versión de NeoRanger"

# Fork de 1.4.3.4 - uGeekPodcast

# Ingrese el token BOT devuelto por BotFather (crear el archivo token.txt)
TOKEN=$(cat token.txt)
TELEGRAMTOKEN=$TOKEN

# Ingrese el ID de usuario maestro para notificaciones de uso (crear el archivo id.txt)
PERID=$(cat id.txt)
PERSONALID=$PERID 
 
# Directorio de usuarios (Ruta donde está nuestra carpeta .batbot en nuestro servidor, Raspberry,...)
BATBOTUSR="/home/pi/.batbot" 

# cree el archivo allowed_users especificando las ID de los usuarios autorizados para enviar los comandos. Una identificación por línea 
ALLOWEDUSER=$BATBOTUSR/allowed_users

# revisar nuevos mensajes cada X segundos:
CHECKNEWMSG=3

# Comandos
# respete este formato: ["/ mi comando"] = '<comando del sistema>'
# Por favor, recuerde eliminar los ejemplos innecesarios
# Para agregar estos comandos a los comandos personalizados,
# usa la función / setcommands en BotFather

declare -A botcommands=(
	["/start"]='exec userlist @USERID:@FIRSTNAME@LASTNAME'
	["/myid"]='echo Tu ID es: @USERID'
        ["/hello"]="echo Hi @USERNAME!"
	["/myuser"]='echo Tu nombre de usuario es: @USERNAME'
	["/ping"]='echo Pong!'
	["/uptime"]="uptime"
	["/add ([0-9]+)"]='exec admadduser @USERID @R1'
	["/del ([0-9]+)"]='exec admdeluser @USERID @R1'
	["/lista"]='exec admlistuser @USERID'
	["/run (.*)"]="exec @R1"
	["/menu"]="echo -e ActionLauncherBot Menu: \n/myid \n/myuser \n/uptime \n/run \n/ping \n/hello \n/add \n/del \n/lista \n/run \n/menu \n/temp \n/df \n/free \n/info \n/who \n/shutdown \n/reboot \n/repoup \n/sysup \n/distup \n/osversion \n/screens \n/weather \n/ps_ram \n/ps_cpu \n/server_torrent_restart \n/nmap_all \n/nmap_active \n/check_voltage \n\n\n/menu"
        ["/temp"]="sudo vcgencmd measure_temp"
        ["/df"]="inxi -p"
        ["/free"]="free -m"
        ["/info"]="screenfetch -n"
        ["/who"]="who"
        ["/shutdown"]="sudo shutdown -h now"
        ["/reboot"]="sudo reboot"
        ["/repoup"]="sudo apt-get update"
        ["/sysup"]="sudo apt-get upgrade -y"
        ["/distup´"]="sudo apt-get dist-upgrade -y"
        ["/osversion"]="lsb_release -a"
        ["/screens"]="screen -list"
        ["/weather"]="inxi -w"
        ["/ps_ram"]="ps aux | awk '{print $2, $4, $11}' | sort -k2r | head -n 10"
        ["/ps_cpu"]="ps -Ao user,uid,comm,pid,pcpu,tty --sort=-pcpu | head -n 6"
        ["/server_torrent_restart"]="sudo service transmission-daemon restart"
        ["/nmap_all"]="sudo nast -m -i eth0"
        ["/nmap_active"]="sudo nast -g -i eth0"
        ["/check_voltage"]="vcgencmd get_throttled"
)

FIRSTTIME=0

echo -e "\nBaTbot v${VERSION}\n"
ABOUTME=`curl -s "https://api.telegram.org/bot${TELEGRAMTOKEN}/getMe"`
if [[ "$ABOUTME" =~ \"ok\"\:true\, ]]; then
	if [[ "$ABOUTME" =~ \"username\"\:\"([^\"]+)\" ]]; then
		echo -e "Nick del BOT:\t @${BASH_REMATCH[1]}"
	fi

	if [[ "$ABOUTME" =~ \"first_name\"\:\"([^\"]+)\" ]]; then
		echo -e "Nombre del Bot:\t ${BASH_REMATCH[1]}"
	fi

	if [[ "$ABOUTME" =~ \"id\"\:([0-9\-]+), ]]; then
		echo -e "Bot ID:\t\t ${BASH_REMATCH[1]}"
		BOTID=${BASH_REMATCH[1]};
	fi

else
	echo "Error: tal vez el token este equivocado ... saliendo"
	exit;
fi

if [ -e "$BATBOTUSR/$BOTID.lastmsg" ]; then
	FIRSTTIME=0;
else
	touch $BATBOTUSR/$BOTID.lastmsg
	FIRSTTIME=1;
fi

echo -e "\nIniciando... Esperando un nuevo mensaje\n"

while true; do
	MSGOUTPUT=$(curl -s "https://api.telegram.org/bot${TELEGRAMTOKEN}/getUpdates")
	MSGID=0
	TEXT=0
	FIRSTNAME=""
	LASTNAME=""
	echo -e "${MSGOUTPUT}" | while read -r line ; do
		if [[ "$line" =~ \"chat\"\:\{\"id\"\:([\-0-9]+)\, ]]; then
			CHATID=${BASH_REMATCH[1]}
		fi

		if [[ "$line" =~ \"message\_id\"\:([0-9]+)\, ]]; then
			MSGID=${BASH_REMATCH[1]}
		fi

		if [[ "$line" =~ \"text\"\:\"([^\"]+)\" ]]; then
			TEXT=${BASH_REMATCH[1]}
			LASTLINERCVD=${line}
		fi

		if [[ "$line" =~ \"username\"\:\"([^\"]+)\" ]]; then
			USERNAME=${BASH_REMATCH[1]}
		fi

		if [[ "$line" =~ \"first_name\"\:\"([^\"]+)\" ]]; then
			FIRSTNAME=${BASH_REMATCH[1]}
		fi

		if [[ "$line" =~ \"last_name\"\:\"([^\"]+)\" ]]; then
			LASTNAME=${BASH_REMATCH[1]}
		fi

		if [[ "$line" =~ \"from\"\:\{\"id\"\:([0-9\-]+), ]]; then
			FROMID="${BASH_REMATCH[1]}"
		fi

	 	if [[ "$line" =~ \"date\"\:([0-9]+)\, ]]; then
			DATE=${BASH_REMATCH[1]}
		fi

		if [[ $MSGID -ne 0 && $CHATID -ne 0 ]]; then
			### comprobar si el usuario está autorizado 
			UserAllowed=$(grep -x "${FROMID}" $ALLOWEDUSER |wc -l)
			LASTMSGID=$(cat "${BOTID}.lastmsg")
			FIRSTNAMEUTF8=$(echo -e "$FIRSTNAME")
			if [[ $MSGID -gt $LASTMSGID ]]; then
				if grep -qe "$(echo $TEXT | awk '{print $1}')" <(echo "${!botcommands[@]}"); then
					echo "[chat ${CHATID}][da ${FROMID}] <${FIRSTNAMEUTF8} ${LASTNAME}> ${TEXT}"
					echo $MSGID > "${BOTID}.lastmsg"
					for s in "${!botcommands[@]}"; do
						if [[ "$TEXT" =~ ${s} ]]; then
							DATENOW=$(date "+%s")
							DATEDIFF=$(( $DATENOW - $DATE ))
							CMDORIG=${botcommands["$s"]}
							CMDORIG=${CMDORIG//@USERID/$FROMID}
							CMDORIG=${CMDORIG//@USERNAME/$USERNAME}
							CMDORIG=${CMDORIG//@FIRSTNAME/$FIRSTNAMEUTF8}
							CMDORIG=${CMDORIG//@LASTNAME/$LASTNAME}
							CMDORIG=${CMDORIG//@CHATID/$CHATID}
							CMDORIG=${CMDORIG//@MSGID/$MSGID}
							CMDORIG=${CMDORIG//@TEXT/$TEXT}
							CMDORIG=${CMDORIG//@FROMID/$FROMID}
							CMDORIG=${CMDORIG//@R1/${BASH_REMATCH[1]}}
							CMDORIG=${CMDORIG//@R2/${BASH_REMATCH[2]}}
							CMDORIG=${CMDORIG//@R3/${BASH_REMATCH[3]}}

							if [[ $UserAllowed -eq 1 ]]; then
								if [[ $FIRSTTIME -eq 1 || $DATEDIFF -gt 10 ]]; then
									echo "Mensaje antiguo, no hay respuesta del usuario"
									curl -s -d "text=Mensaje antiguo&chat_id=${PERSONALID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
								else
									echo "Comando ${s} recibido, ejecuto: ${CMDORIG}"
									CMDOUTPUT=`$CMDORIG`
									curl -s -d "text=${CMDOUTPUT}&chat_id=${CHATID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
									if [[ ${FROMID} != ${PERSONALID} ]]; then
										curl -s -d "text=${s} recibido de ${FIRSTNAMEUTF8} ${LASTNAME} ${FROMID}&chat_id=${PERSONALID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
									fi
								fi
							else
								if [[ ${s} == "/ilmioid" ]]; then
									CMDOUTPUT=`$CMDORIG`
									curl -s -d "text=${CMDOUTPUT}&chat_id=${CHATID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
								else
									CMDOUTPUT="BOT Privado. No estas autorizado a utilizarlo! tu ID es: ${FROMID}, Comunicate con el administrador para que te habilite."
									echo "Tu nombre no está en la lista: ${s} recibido por ${FIRSTNAMEUTF8} ${FROMID}"
									curl -s -d "text=${CMDOUTPUT}&chat_id=${CHATID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
									if [[ ${FROMID} != ${PERSONALID} ]]; then
										curl -s -d "text=Usuario no habilitado: ${s} recibido de ${FIRSTNAMEUTF8} ${FROMID}&chat_id=${PERSONALID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
									fi
									if [[ ${s} == "/start" ]]; then
										userlist ${FROMID}:${FIRSTNAMEUTF8}${LASTNAME}
									fi
								fi
							fi

						fi
					done
				else
					echo $MSGID > "${BOTID}.lastmsg"
					if [[ $UserAllowed -eq 1 ]]; then
						echo "Comando $TEXT no reconocido"
						curl -s -d "text=Comando $TEXT no reconocido.&chat_id=${CHATID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
						if [[ ${FROMID} != ${PERSONALID} ]]; then
							curl -s -d "text=$TEXT no reconocido recibido de ${FROMID} ${FIRSTNAMEUTF8} ${LASTNAME}&chat_id=${PERSONALID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
						fi
					else
						CMDOUTPUT="¡No estás autorizado para ejecutar este comando!"
						echo "Comando no habilitado : ${s} recibido de ${FROMID} ${FIRSTNAMEUTF8}"
						curl -s -d "text=${CMDOUTPUT}&chat_id=${CHATID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
						if [[ ${FROMID} != ${PERSONALID} ]]; then
							curl -s -d "text=Comando no habilitado: ${s} recibido de ${FROMID} ${FIRSTNAMEUTF8} ${LASTNAME}&chat_id=${PERSONALID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
						fi
					fi
				fi
			fi
		fi
	done

	FIRSTTIME=0;

	read -t $CHECKNEWMSG answer
	if [[ "$answer" =~ ^\.msg.([\-0-9]+).(.*) ]]; then
		CHATID=${BASH_REMATCH[1]}
		MSGSEND=${BASH_REMATCH[2]}
		curl -s -d "text=${MSGSEND}&chat_id=${CHATID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
	elif [[ "$answer" =~ ^\.msg.([a-zA-Z]+).(.*) ]]; then
		CHATID=${BASH_REMATCH[1]}
		MSGSEND=${BASH_REMATCH[2]}
		curl -s -d "text=${MSGSEND}&chat_id=@${CHATID}" "https://api.telegram.org/bot${TELEGRAMTOKEN}/sendMessage" > /dev/null
	fi


done

exit 0
