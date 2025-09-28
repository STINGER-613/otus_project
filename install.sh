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
apt_tools=(git network-manager net-tools wget curl zsh apache2 nginx mysql-server* net-tools iptables)
#sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

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


echo -e "$slash\nОтключение|остановка служб...\n$slash"
sudo systemctl disable nginx.service apache2.service mysql.service &>/dev/null
sudo systemctl stop nginx.service apache2.service mysql.service &>/dev/null
echo -e "Complite!\n$slash"

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
	cd /home/$(whoami)/
	git clone git@github.com:STINGER-613/otus_project.git &>/dev/null
	echo -e "Файлы скопированы!\n$slash"
	sleep 3s; clear
fi

########################################################################
# Выбор действия с сервером
########################################################################

echo -e "$slash\nВыбор действия с сервером\n$slash"
read -rp "Какая цель у сервера:

1) Nginx (frontend)
2) Apache2 (backend)
3) Mysql (master)
4) Mysql (slave)
5) Grafana
-> " i

echo $slash
case $i in
	1) echo -e "Настройка Nginx (frontend)\n$slash"
	read -rp "Присвоить IP сервера > " q
	sed -i '6s/ip/$q/g' ~/otus_project/FILES/netplan/50-cloud-init.yaml
	echo "Копирование конфигурации сети..."
	sudo cp -r ~/otus_project/FILES/netplan/50-cloud-init.yaml /etc/netplan/
	sleep 1s
	echo "Копирование конфигурации nginx..."
	sudo cp -r ~/otus_project/FILES/nginx/default /etc/nginx/sites-available/
	sleep 1s
	echo -e "Готово! IP адрес сервеа $q, Nginx настроен!\n$slash"
	;;
	2) echo -e "Настройка Apache2 (backend)\n$slash"
	;;
	3) echo -e "Настройка Mysql (master)\n$slash"
	;;
	4) echo -e "Настройка Mysql (slave)\n$slash"
	;;
	5) echo -e "Настройка Grafana (monitoring)\n$slash"
	;;
	*) echo -e "Ошибка назначения!"; exit
esac


