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
5) Grafana (monitoring)
-> " i

echo $slash
case $i in
	1) echo -e "Настройка Nginx (frontend)\n$slash"
	echo "Копирование конфигурации сети..."
	sudo cp -r ~/otus_project/FILES/netplan/50-cloud-init.yaml /etc/netplan/
	sleep 1s
	read -rp "Присвоить IP сервера > " q
	sudo sed -i "6s/ip/$(echo $q)/g" /etc/netplan/50-cloud-init.yaml
	sleep 1s
	echo "Копирование конфигурации nginx..."
	sudo cp -r ~/otus_project/FILES/nginx/default /etc/nginx/sites-available/
	sleep 1s
	echo "Запуск служб Nginx..."
	sleep 1s; sudo systemctl enable nginx.service; sudo systemctl start nginx.service &>/dev/null
	echo -e "Готово! IP адрес сервера $(echo $q)\nNginx настроен!\nОжидается перезагрузка...\n$slash"
	sleep 5s; sudo reboot
	;;

	2) echo -e "Настройка Apache2 (backend)\n$slash"
	echo "Копирование конфигурации сети..."
	sudo cp -r ~/otus_project/FILES/netplan/50-cloud-init.yaml /etc/netplan/
	sleep 1s
	read -rp "Присвоить IP сервера > " q
	sudo sed -i "6s/ip/$(echo $q)/g" /etc/netplan/50-cloud-init.yaml
	sudo netplan apply
	sleep 1s
	echo "Копирование конфигурации Apache2 и стартовой страници..."
	sudo cp -r ~/otus_project/FILES/apache2/000-default.conf /etc/apache2/sites-available/
	sudo cp -r ~/otus_project/FILES/apache2/index.html /var/www/html/
	sudo cp -r ~/otus_project/FILES/apache2/ports.conf /etc/apache2
	sudo sed -i "10s/ip/$(echo $q)/g" /var/www/html/index.html
	sleep 1s
	echo "Запуск служб Apache2..."
	sleep 1s; sudo systemctl enable apache2.service; sudo systemctl start apache2.service &>/dev/null
	echo -e "Готово! IP адрес сервера $(echo $q)\nApache2 настроен на порту 8080!\nОжидается перезагрузка...\n$slash"
	sleep 5s; sudo reboot
	;;

	3) echo -e "Настройка Mysql (master)\n$slash"
	echo "Копирование конфигурации сети..."
	sudo cp -r ~/otus_project/FILES/netplan/50-cloud-init.yaml /etc/netplan/
	sleep 1s
	read -rp "Присвоить IP сервера > " q
	sudo sed -i "6s/ip/$(echo $q)/g" /etc/netplan/50-cloud-init.yaml
	sudo netplan apply
	sleep 1s
	echo "Копирование конфигурации в mysql.conf.d..."
	sudo cp ~/otus_project/FILES/mysql/mysqld.cnf /etc/mysql/mysql.conf.d/
	sleep 1s
	read -rp "Укажите адрес Slave > " w
	sudo sed -i "83s/ip/$(echo $q)/g" /etc/mysql/mysql.conf.d/mysqld.cnf
	sudo sed -i "81s/numbers/1/g" /etc/mysql/mysql.conf.d/mysqld.cnf
	sleep 1s
	echo "Создание пользователя из файла конфигурации для адреса ..."
	cp ~/otus_project/FILES/mysql/master.sql ~/
	sed -i "s/ip/$(echo $w)/g" ~/master.sql
	mysql < ~/master.sql
	echo -e "Пользователь создан!\nРеплика запущена!\nОжидается перезагрузка..."
	sleep 1s; sudo systemctl enable mysql.service; sudo systemctl start mysql.service &>/dev/null
	sleep 5s; sudo reboot
	;;

	4) echo -e "Настройка Mysql (slave)\n$slash"
	echo "Копирование конфигурации сети..."
	sudo cp -r ~/otus_project/FILES/netplan/50-cloud-init.yaml /etc/netplan/
	sleep 1s
	read -rp "Присвоить IP сервера > " q
	sudo sed -i "6s/ip/$(echo $q)/g" /etc/netplan/50-cloud-init.yaml
	sudo netplan apply
	sleep 1s
	echo "Копирование конфигурации в mysql.conf.d..."
	sudo cp ~/otus_project/FILES/mysql/mysqld.cnf /etc/mysql/mysql.conf.d/
	sleep 1s
	read -rp "Укажите адрес Master > " w
	sudo sed -i "83s/ip/$(echo $q)/g" /etc/mysql/mysql.conf.d/mysqld.cnf
	sudo sed -i "81s/numbers/2/g" /etc/mysql/mysql.conf.d/mysqld.cnf
	sleep 1s
	echo "Подключение к мастеру Mysql по адресу $w..."
	cp ~/otus_project/FILES/mysql/slave.sql ~/
	read -rp "Укажите номер 'log' Mysql-master > " e
	read -rp "Укажите номер 'pos' Mysql-master > " r
	sed -i "3s/ip/$(echo $w)/g" ~/master.sql
	sed -i "6s/log/$(echo $e)/g" ~/master.sql
	sed -i "7s/pos/$(echo $r)/g" ~/master.sql
	sleep 1s
	sudo mysql < ~/master.sql
	echo -e "Реплика запущена в сторону $w!\nОжидается перезагрузка..."
	sleep 1s; sudo systemctl enable mysql.service; sudo systemctl start mysql.service &>/dev/null
	sleep 5s; sudo reboot
	;;

	5) echo -e "Настройка Grafana (monitoring)\n$slash"
	echo "Копирование конфигурации сети..."
	sudo cp -r ~/otus_project/FILES/netplan/50-cloud-init.yaml /etc/netplan/
	sleep 1s
	read -rp "Присвоить IP сервера > " q
	sudo sed -i "6s/ip/$(echo $q)/g" /etc/netplan/50-cloud-init.yaml
	sudo netplan apply
	sleep 1s
	sleep 5s; sudo reboot
	;;

	*) echo -e "Ошибка назначения!"; exit
esac


