#!/usr/bin/env bash

########################################################################
# Подготовка сервера
########################################################################
slash="---------------------------------------------"
clear
echo -e "$slash\nОбновление...\n$slash"
sudo apt-get update -y 1>/dev/null

clear
echo -e "$slash\nУстановка пакетов и их зависимостей...\n$slash"; sleep 2s
apt_tools=(git network-manager wget curl apache2 nginx mysql-server* net-tools iptables)

for i in ${apt_tools[@]}; do
	sudo apt-get install $i -y 1>/dev/null
	if [ $? -eq 0 ]; then
		echo "[$i] -> Установлено!"
	else
		echo "[$i] -> Не установлено!"
		sleep 2s; exit
	fi
done

sudo systemctl disable apache2.service nginx.service mysql.service --now &>/dev/null
sudo systemctl stop apache2.service nginx.service mysql.service &>/dev/null

sleep 1s
echo -e "\nComplite!\n$slash"
sleep 2s

clear
########################################################################
# Выбор действия с сервером
########################################################################

echo -e "$slash\nВыбор действия с сервером\n$slash"
read -rp "Какая цель у сервера:

1) Nginx (frontend)
2) Apache2 (backend)
3) Mysql (master)
4) Mysql (slave)
5) Monitoring + Logs

-> " i

echo $slash
case $i in
	1)~/otus_project/FILES/SCRIPTS/Nginx;;
	2)~/otus_project/FILES/SCRIPTS/Apache2;;
	3)~/otus_project/FILES/SCRIPTS/Mysql_Master;;
	4)~/otus_project/FILES/SCRIPTS/Mysql_Slave;;
	5)~/otus_project/FILES/SCRIPTS/Monitoring;;

	*) echo -e "Ошибка назначения!"; read -rp "Нажмите любую клавишу для продолжения!"; exit;;
esac


