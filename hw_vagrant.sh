#!/usr/bin/env bash

yum install postfix mutt
#Отключаем в настройках postfix-a протокол IPv6

if [[ ! grep 'inet_protocols = ipv4/' /etc/postfix/main.cf ]]
    then 
            sed -i  '/inet_protocols/s/inet_protocols = all/inet_protocols = ipv4/' /etc/postfix/main.cf
            
fi
            
systemctl start postfix

fs=/var/spool/cron/vagrant

#Проверим крон-файл пользователя vagrant, на наличие записи о запуске скрипта генерации лог файла analise_log_file.txt каждую минуту. Запустим расписание под управлением flock утилиты, которая предотвращает повторный запуск файла генерации (hw_genlog.sh), а при попытке такого запуска, блокирует второй процесс и через 20 секунд завершает его, если первый процесс не закончился к этому времени.  
if [[ ! grep '*/1 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_genlog.lock -c /vagrant/hw_genlog.sh ' $fs ]]
    then 
            echo "*/1 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_genlog.lock -c /vagrant/hw_genlog.sh" >> $fs 
fi

#Такой же запуск скрипта для анализа лог-файла analise_log_file.txt, Тоже под управлением flock.
if [[ ! grep '*/3 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_bash.lock -c /vagrant/hw_bash.sh ' $fs ]]
    then 
            echo "*/3 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_bash.lock -c /vagrant/hw_bash.sh" >> $fs 
fi
