#!/usr/bin/env bash

########################################################################
# Подготовка сервера
########################################################################

slash="---------------------------------------------"

clear

echo -e "$slash\nОбновление...\n$slash"
sudo apt-get update -y &>/dev/null
clear
echo -e "$slash\nУстановка пакетов и их зависимостей...\n$slash"; sleep 2s
apt_tools=(git net-tools wget curl zsh apache2 nginx mysql-server* net-tools iptables)

for i in ${apt_tools[@]}; do
	sudo apt-get install $i -y &>/dev/null
	if [ $? -eq 0 ]; then
		echo "[$i] -> Установлено!"
		sleep 1s
	else
		echo "[$i] -> Не установлено!"
		sleep 2s; exit
	fi
done


echo -e "$slash\nОтключение|остановка служб apache2 и mysql...\n$slash"
sudo systemctl disable apache2.service mysql.service &>/dev/null
sudo systemctl stop apache2.service mysql.service &>/dev/null|echo "Complite!"
echo $slash

########################################################################
#Github check
########################################################################
sleep 2s
ping -c 2 github.com &>/dev/null

if [ $? != 0 ]; then 
	echo "Отсутствует подключение к [GITHUB]"
	sleep 1s
	exit 0
else
	echo "Скачивание репозитория OTUS_PROJECT..."
	cd /home/$(whoami)/Desktop
	git clone git@github.com:STINGER-613/otus_project.git &>/dev/null
	echo -e "Файлы скопированы на рабочий стол!\n$slash"
	sleep 3s
fi

########################################################################
# Выбор действия с сервером
########################################################################
clear
echo -e "$slash\nВыбор действия с сервером\n$slash"
read -rp "Какая цель у сервера:

1) Nginx (frontend)
2) Apache2 (backend)
3) Mysql (master)
4) Mysql (slave)

-> " i

echo $slash
case $i in
	1) echo -e "Настройка Nginx (frontend)\n$slash"
	;;
	2) echo -e "Настройка Apache2 (backend)\n$slash"
    ;;
	3) echo -e "Настройка Mysql (master)\n$slash"
	;;
	4) echo -e "Настройка Mysql (slave)\n$slash"
    ;;
esac


