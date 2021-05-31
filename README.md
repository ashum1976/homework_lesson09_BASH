#                                                               1. ДЗ
##          1.1 Краткий алгоритм работы

По заданию, необходимо запустить анализатор лог-файла, который будет запускаться по cron-у (по условию раз в час, но это долго) раз в 3 минуты, с защитой от возможного вторичного запуска этого же анализатора. Лог-файл генерируется из тестового лог-файла, где скрипт генерации симулирует работу веб-сервера. Запускается генератор тоже по крону раз в минуту, из эталонного лог-файла копируются 5 строк в новый, который и проверяется анализатором.

После запуска виртуальной машины, и отработки скрипта старта в vagrant файле. Добавляются две записи в крон-файл пользователя vagrant.

1.  **_*/1 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_genlog.lock -c /vagrant/hw_genlog.sh_**
2.  **_*/3 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_bash.lock -c /vagrant/hw_bash.sh_**

Перевая --  запускает генератор лог-файла, для проверки анализатором. Скрипт запускается каждую минут, и находится под управлением flock утилиты, предотвращающей запуск второго такого процесса.
Вторая -- запускает сам анализатор лог-файла, формирует и отсылает почту пользователю vagrant. Всё тоже под управлением flock утилиты.

___
_

##         1.2 Текст скриптов для выполнения ДЗ

<details>
                <summary>Скрипты для выполнения ДЗ</summary>
    <details>
                    <summary>Скрипт для запуска с вагрант файлом</summary>

    #!/usr/bin/env bash

    #Устанавливаем необходимые пакеты - postfix, mutt <--- почтовый клиент
    yum install postfix mutt

    #Отключаем в настройках postfix-a протокол IPv6

    if [[ ! $(grep 'inet_protocols = ipv4' /etc/postfix/main.cf) ]]
    then
            sed -i  '/inet_protocols/s/inet_protocols = all/inet_protocols = ipv4/' /etc/postfix/main.cf

    fi

    #Запускаем почтовый сервер postfix, для приёма сообщения для vagrant-a
    systemctl start postfix

    mkdir -p /var/tmp/log                   <---- Создадим рабочий каталог, для работы скриптов генерации и анализа

    #Расположение крон-файла пользователя vagrant
    touch  /var/spool/cron/vagrant
    chmod 600 /var/spool/cron/vagrant
    chown vagrant: /var/spool/cron/vagrant

    #Lock файл для работы утилиты flock, с нужными доступами и разрешениями
    touch /var/tmp/log/hw_genlog.lock && echo "lock file create !!!!!"
    chmod 600 /var/tmp/log/hw_genlog.lock
    chown  vagrant:vagrant /var/tmp/log/hw_genlog.lock

    fs=/var/spool/cron/vagrant

    #Проверим крон-файл пользователя vagrant, на наличие записи о запуске скрипта генерации лог файла analise_log_file.txt каждую минуту. Запустим расписание под управлением flock утилиты, еоторая предотвращает повторный запуск файла генерации (hw_genlog.sh), а при попытке такого запуска, блокирует второй процесс и через 20 секунд завершает его, если первый процесс не закончился к этому времени.
    #С помощью генератора лог-файла, имитируем работу веб сервера. Запускается каждую минуту.
    if [[ ! $(grep '*/1 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_genlog.lock -c /vagrant/hw_genlog.sh' $fs) ]]
    then
            echo "*/1 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_genlog.lock -c /vagrant/hw_genlog.sh" > $fs
            chmod 600 $fs
    fi

    #Такой же запуск скрипта для анализа лог-файла analise_log_file.txt, Тоже под управлением flock.
    if [[ ! $(grep '*/3 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_bash.lock-c /vagrant/hw_bash.sh' $fs) ]]
        then
                echo "*/3 * * * * /usr/bin/flock -w 20 -x /var/tmp/log/hw_bash.lock -c /vagrant/hw_bash.sh" >> $fs

    fi

</details>
    <details>
                    <summary>Скрипт анализа лог файла</summary>

    # log_all_string.txt                <----- Промежуточный файл, создаваемый в процессе работы анализатора, хранит число всех строк в анализируемом файле
    # log_date_save_last.txt       <---- Файл создаваемый для хранения значения даты/времени последней строки анализируемого файла. Используется для определения точки старта, при повторном запуске анализатора.
    #report_stat_file.txt              <---- Формируемый файл отчёта, отправляемый пользователю

    mkdir -p /var/tmp/log
    filelog=./analise_log_file.txt  <---- Анализируемый файл
    filedata=/var/tmp/log/              <----- Путь хранения всех создаваемых файлов, для скрипта-анализатора


    #Если такой файл (log_all_string.txt ) существует, то проверить число строк в log файле если равно текущему значению, то выйти.

    if [[ -f ${filedata}log_all_string.txt ]]
            then
                        #Проверяем, что файл  нулевой длинны, тогда выходим, и подготавиваем для повторного анализа систему.
                        if [[ $(cat ${filedata}log_all_string.txt | wc -l) = 0  ]]
                                then
                                        echo "Файл нулевой длинны, анализ закончен"
                                        rm ${filedata}log_all_string.txt
                                        exit 0

                        elif [[ sf=$(cat ${filedata}log_all_string.txt) -eq fs=$(nl ${filelog} | tail -n1 | awk -F" " '{print $1}') ]]
                                then   
                                        echo "Файл не поменялся"
                                        exit 0

                        # Проверяем, если значение в файле log_date_end больше чем значение числа строк из текущего файла, то это значит, что или новый файл или был изменён.
                        elif [[ sf=$(cat ${filedata}log_all_string.txt) -gt fs=$(nl ${filelog} | tail -n1 | awk -F" " '{print $1}') ]]
                                then
                                        # Пронумеровать строки с помощью nl, получить значение последней строки, сохранить её номер.

                                        echo "$sf" > ${filedata}log_all_string.txt

                                        #Инициируем новую переменную с параметром даты первой строки логфайла.
                                        log_date_first=$(head -n1 ${filelog} | awk -F" " '{print $4}' | tr -d [ )

                                        #Заносим значение последней даты с помощью tee,  в переменную и в файл на диске.
                                        log_date_last=$(tail -n1 ${filelog} | awk -F" " '{print $4}' | tr -d [ | tee ${filedata}log_date_save_last.txt )

                                        #Переменная, для вставки временного интервала в письмо для пользователя vagrant
                                        #mail_log_time=$(echo "Период обработки записей:  $log_date_first - $log_date_last")

                                        # Переменная с уникальными IP,  сортировкой по первому полю (в нём частота появления IP)  по убывающей, лог файла

                                        awk_sort=$(cat ${filelog} | awk -F" " '{print $1}' | sort -nr |  uniq -c  | sort -nr)

                                        # Переменная с IP адресами из лог файла

                                        ip_sort=$(echo "$awk_sort" | awk -F" " '{print $2}')

                                        # Переменная с числом появления одинаковых IP, для определения какие IP будем анализировать по количеству их появления в лог файле.

                                        ip_num=$(echo "$awk_sort" | awk -F" " '{print $1}')

                                        #Переменная для цикла определния количества анализируемых IP

                                        ip_nm=$(echo "$ip_num" | wc -l)

                        # Запуск анализатора лог файла уже выполнялся, продолжаем анализировать с последней точки запуска.        
                        else
                                        echo "Test существующего файла"
                                        #Создаём две переменных, для вывода временного интервала, в котором будет отрабатывать скрипт, по проверке лог файла.
                                        log_date_first=$(cat ${filedata}log_date_save_last.txt)
                                        log_date_last=$(tail -n1 ${filelog} | awk -F" " '{print $4}' | tr -d [)

                                        #Переменная, для вставки временного интервала в письмо для пользователя vagrant
                                        #mail_log_time=$(echo "Период обработки записей:  $log_date_first - $log_date_last")

                                        awk_nm_string=$(nl ${filelog} | tail -n1 | awk -F" " '{print $1}' | tee ${filedata}log_all_string.txt)

                                        # Переменная с уникальными IP, с сортировкой по первому полю (в нём частота появления IP)  по убывающей, лог файла. Отбор начинается с сохранённой позиции, от предыдущего запуска
                                        awk_sort=$(tail -n +$(cat ${filedata}log_all_string.txt) $filelog  | awk -F" " '{print $1}' |  sort -nr |  uniq -c  | sort -nr)

                                        # Переменная с IP адресами из лог файла
                                        ip_sort=$(echo "$awk_sort" | awk -F" " '{print $2}')

                                        # Переменная с числом появления одинаковых IP, для определения какие IP будем анализировать по количеству их появления в лог файле.
                                        ip_num=$(echo "$awk_sort" | awk -F" " '{print $1}')

                                        #Переменная для цикла определния количества анализируемых IP
                                        ip_nm=$(echo "$ip_num" | wc -l)

                        fi       

            else
                    echo "Test нового файла"
                    # Пронумеровать строки с помощью nl, получить значение последней строки, сохранить её номер.
                    awk_nm_string=$(nl ${filelog} | tail -n1 | awk -F" " '{print $1}' | tee  ${filedata}log_all_string.txt)

                    #Инициируем новую переменную с параметром даты первой строки логфайла.
                    log_date_first=$(head -n1 ${filelog} | awk -F" " '{print $4}' | tr -d [ )

                    #Заносим значение последней даты с помощью tee,  в переменную и в файл на диске.
                    log_date_last=$(tail -n1 ${filelog} | awk -F" " '{print $4}' | tr -d [ | tee ${filedata}log_date_save_last.txt )

                    # Переменная с уникальными IP,  сортировкой по первому полю (в нём частота появления IP)  по убывающей, лог файла

                    awk_sort=$(cat ${filelog} | awk -F" " '{print $1}' |  sort -nr |  uniq -c  | sort -nr)

                    # Переменная с IP адресами из лог файла

                    ip_sort=$(echo "$awk_sort" | awk -F" " '{print $2}')

                    # Переменная с числом появления одинаковых IP, для определения какие IP будем анализировать по количеству их появления в лог файле.

                    ip_num=$(echo "$awk_sort" | awk -F" " '{print $1}')

                    #Переменная для цикла определния количества анализируемых IP. Количество уникальных IP

                    ip_nm=$(echo "$ip_num" | wc -l)


    fi
    #Переменная содержащая анализируемый  период из лог файла
    mail_log_time=$(echo "$log_date_first - $log_date_last")

    echo "Всего за  промежуток $mail_log_time зафиксированно $ip_nm уникальных адресов $ip_sort" > ${filedata}report_stat_file.txt

    # Подготовим файл для записи IP адресов, наиболее часто встречающихся
    > ip_analise

    #Создадим два массива ( очень массивы именно для этого подходят, чтобы задать и обрабатывать много значений (IP или число появлений IP адрессов в файле) полученных от работы потокового редактора sed или awk )

    array_ip=( $(echo $ip_sort) )           # <---- Массив iP адресов
    array_num=( $(echo $ip_num) )       # <---- Массив количества появлений IP адрессов

    i=0
    while (( $i < ${#array_ip[@]} ))
            do
                echo "Test array "
                if [[ ${array_num[$i]} -ge 5 ]]
                    then
                        echo "Tst create report file"
                        arr=${array_ip[$i]}
                        array_ip_analise+=($arr)
                        echo ${array_ip[$i]} >> ip_analise # <---- Временный файл, содержащий IP которые будем обрабатывать.
                        err_404=$(grep "${array_ip_analise[$i]}" ${filelog} | grep '404' | wc -l)
                        cl1=$(echo "Клиент: ${array_ip_analise[$i]} заходил на сервер: ${array_num[$i]} раз")  
                        cl2=$(echo " Ошибка 404 от клиента ${array_ip_analise[$i]} при доступе к web - $err_404")
                        echo "$cl1 --  $cl2" >> ${filedata}report_stat_file.txt
                        echo "" >> ${filedata}report_stat_file.txt
                fi
                (( i++ ))
    done

    #Вставляем текст перед второй строкой
    sed -i '2i IP адреса клиентов подлежащих анализу:' ${filedata}report_stat_file.txt
    #Вставляем текст после второй строки
    sed -i '2r ip_analise' ${filedata}report_stat_file.txt

    #Отправляем пользователю vagrant почту с отчётом
    mutt -s "Анализ лог файла ${filelog}, за период ${mail_log_time}" vagrant@localhost < ${filedata}report_stat_file.txt && rm ${filedata}report_stat_file.txt


</details>
    <details>
                    <summary>Скрипт генератор лог файла</summary>


    #!/usr/bin/env bash

    #Переменная содержащая эталонный лог-файл (access-*.log лежит в папке пользователя vagrant), из которого будем генерировать рабочий лог-файл (analise_log_file.txt) для анализатора
    logfile=$(ls access-*.log 2>/dev/null)  

    if [[  -e "$logfile" && ! -e  ./analise_log_file.txt ]]

        then
                head -n 5 $logfile > ./analise_log_file.txt
                tail -n +6  $logfile > ./var_log_file                   #<---- Промежуточный файл для создания рабочего лог-файла (analise_log_file)
                mv ./var_log_file $logfile

        elif [[ -e "$logfile" && -e  ./analise_log_file.txt ]]

            then
                    head -n 5 $logfile >> ./analise_log_file.txt
                    tail -n +6  $logfile > ./var_log_file
                    mv ./var_log_file $logfile
        else
                echo "Log файла для анализа не найден"
                exit 1
    fi

</details>
</details>                                         

Для предотвращения повторного запуска скрипта, будем использовать стандартную утилиту в Linux flock.  Находится в пакете
util-linux

Пример запуска скрипта:

    /usr/bin/flock -w 20 -x /var/tmp/log/hw_genlog.lock -c /vagrant/hw_genlog.sh

    где:
        -w 20 <--- при повторном запуске flock ожидает освобождения блокировки от первого запуска указанное значение сек. Если блокировка не снята, второй  процесс завершается.
        -n    <---- Немедленное завершение процесса, если блокировка не может быть получена. Т.е второй запуск завершается сразу, без ожиданя возможного завршения первого запуска (/usr/bin/flock -n -E 20 /var/tmp/log/hw_bash.lock -c ./hw_genlog.sh). Код завршения будет - 20
        -x    <---- эксклюзивная блокировка (блокировка записи запись), может быть другой вариант блокировки ( блокировка чтения)
         /var/tmp/log/hw_genlog.lock <---   при вызове надо будет указать файл блокировки, должен находится в директории с правами на запись.






         yum install postfix mutt

/etc/postfix/main.cf (найти строку inet_protocols=all и заменить на inet_protocols=ipv4 )

systemctl postfix restart







Если нужно просто вставить текст из file1  после после второй строки файла file2.txt:
$ sed -i '2r file1.txt' file2.txt

Если нужно просто вставить текст из file1  перерд второй строкой файла file2.txt:
sed -i '2i IP адреса клиентов подлежащих анализу:' report_stat_file.txt

___
___


#              2. Теория BASH

##          2.1 Hot keys BASH


1.  **Ctrl+a Ctrl+e                 :** <----- *Возврат курсорав начало строки, переход курсора в конец строки*

2.  **Alt+f Alt+b                    :**  <----- _Перемещение на слово вперёд, премещение на слово назад_

3.  **Ctrl+w                           :**   <---- _Ctrl+w - удаляет слово до курсора (при этом копируя его в буфер обмена)_

-.  **Alt+d                              :** <----- _Удаляет слово после курсора_   

4.  **Ctrl+u                            :** <---- _Удаляет всю строку до курсора_

5.  **Ctrl+k                            :** <----   _Удаляет всю строку после курсора_

-.  **Ctrl+r                            :**   <---- _Поиск по строке

        Ctrl+j                     : <----   Закончить поиск по истории
        Ctrl+g                     : <----   Закончить поиск и вернуть строку к прежнему состоянию

___

##          2.2 Перенаправления в BASH

<details>
                <summary> Перенаправление "<< - HERE TEXT"  </summary>

    wc -l << EOF
    Ssss
    Sdsd
    Sdsd
    EOF

</details>

<details>
                <summary> Перенаправление "<<< - HERE TEXT"  </summary>

    $ read first second <<< "hello world"
    $ echo $second $first
</details>

<details>
                <summary> Перенаправление "<<< - HERE DOC"  </summary>

    cat <<-EOF > myscript.sh
/#!/bin/bash
echo “Hello Linux!!!”
exit 0
EOF
Пример из скрипта, создание файла в каталоге /etc/sudoers.d/tester
if [[ ! -e /etc/sudoers.d/tester ]]
  then
    cat <<EOF  > /etc/sudoers.d/tester
Cmnd_Alias DOCKER = /bin/systemctl restart, /bin/docker
%tester secsrv=(root) NOPASSWD: DOCKER
EOF
  fi

</details>

___

##          2.3 Переменные в BASH


*   **set              :**    <---- _установка атрибутов переменных_

*   **declare       :**    <---- _установка значений переменных и управление атрибутами переменных_

*   **export         :**  _Все объявленные с помощью нее переменные экспортируются во внешнее окружение среды и будут доступны всем скриптам и программам. С помощью опции -p вы можете посмотреть экспортированные на данный момент переменные._

<details>
                <summary> Специальные переменные:  </summary>


     $@ — параметры скрипта (столбик), если переменная в кавычках -  "$@", иначе строка. Без кавычек  в переменных $@ и $* нет разницы
     $* - все параметры скрипта (строка) если переменная в кавычках - "$*", иначе строка. Без кавычек  в переменных $@ и $* нет разницы
     $0 — имя скрипта
     $1 , $2 , $3 , ... — параметры скрипта, по одному
     $# — количество параметров
     $? — статус выхода последней выполненной команды
     $$ — PID оболочки
     $! — PID последней выполненной в фоновом режиме команды
</details>

**Способы задания переменных**

    export var=value
    var=value
    declare var=value
    var=`ls`
    var=$(uname -r)
    var=$((2+3))
    var=$(expr 3 + 7)
    var1="${var1:-default value}"


<details>
                <summary>/usr/bin/env</summary>

    #!/usr/bin/env VAR=VALUE bash

    -i, --ignore-environment
    start with an empty environment

    -0, --null
    end each output line with NUL, not newline

    -u, --unset=NAME
    remove variable from the environment

    -C, --chdir=DIR
    change working directory to DIR

    -S, --split-string=S
    process and split S into separate arguments; used to pass multiple arguments on shebang lines
</details>

Запуск программы на основе переменных окружения. Могут быть установлены свои переменные, или модифицированы существующие.
Основная идея - улучшение переносимости. Не гарантируется, что на различных системах исполняемый файл будет лежать по пути, который указан в shebang.
Использование env позволяет снизить этот риск за счет запуска команды на основе данных из переменной среды PATH
Более того, если по каким-либо причинам вместо стандартного исполняемого файла пользователь хочет использовать свой, то ему достаточно добавить путь к этому файлу в PATH без необходимости исправления скриптов

>  пример: в Linux bash лежит в /bin/bash, а во FreeBSD в /usr/local/bin/bash. #!/usr/bin/env bash - такой вариант использование she-bang запустится в обоих системах


___


##          2.4 Команды, программы, утилиты в BASH      

[ Ссылка на основные команды BASH ]( https://losst.ru/osnovnye-komandy-bash )  

[ Ссылка на команды терминала linux ](https://losst.ru/komandy-terminala-linux)


*   **column            :**  _Формирование вывода, в виде таблицы с разбивкой полей по значению разделителя
        Параметры запуска:
        -s   <---- Разделитель полей, по которому будут колонки фрмироваться( "пробел", "|" и т.д.)
___

*   **flock             :** _Для предотвращения повторного запуска скрипта, программы и т.д.  используется стандартная утилиту в Linux flock.  Находится в пакете util-linux


<details>
    <summary>Примеры команды flock </summary>

    /usr/bin/flock -w 20 -x /var/tmp/log/hw_genlog.lock -c /vagrant/hw_genlog.sh

    где:
            -w 20 <--- при повторном запуске flock ожидает освобождения блокировки от первого запуска указанное значение сек. Если блокировка не снята, второй  процесс завершается.
            -n    <---- Немедленное завершение процесса, если блокировка не может быть получена. Т.е второй запуск завершается сразу, без ожиданя возможного завршения первого запуска (/usr/bin/flock -n -E 20 /var/tmp/log/hw_bash.lock -c ./hw_genlog.sh). Код завршения будет - 20
            -x    <---- эксклюзивная блокировка (блокировка записи запись), может быть другой вариант блокировки ( блокировка чтения)
            /var/tmp/log/hw_genlog.lock <---   при вызове надо будет указать файл блокировки, должен находится в директории с правами на запись.

</details>

*   **case  EXPR in   :**  _Команда проверки  выражения:_

<details>
    <summary>Примеры команды case </summary>

    CASE1) команды
    ;& # отработать следующие команды без проверки
    CASE2) команды
    ;;& # выполнить следующую проверку
    ...
    CASEN) команды
    ;; # закончить на этом
    esac
</details>

___


*   **find              :** _Find - это одна из наиболее важных и часто используемых утилит системы Linux. Это команда для поиска файлов и каталогов на основе специальных условий. Ее можно использовать в различных обстоятельствах, например, для поиска файлов по разрешениям, владельцам, группам, типу, размеру и другим подобным критериям._

<details>
    <summary>Примеры команды find </summary>

    Изменение атрибутов файлов в папках

    find ./ -type f -exec chmod -X '{}' \;  <----- Изменить атрибуты файлов ( -type f), убрать атрибут, что этот файл исполняемый, если он таковым не является
    find /proc/* -maxdepth 1 -type d -regextype sed -regex '^/proc/[0-9]\{1,30\}'  <-----  Тип регулярного выражения "-regextype sed -regex" , и само регулярное выражение - '^/proc/[0-9]\{1,30\}' отображает папки в каталоге /proc/ название их состоит из цифр (PID-s)
</details>

___

*   **ionice            :** _Команда ionice предназначена для  изменения класса планирования и приоритета ввода/вывода процесса. Данная команда позволяет управлять временем, в течение которого процесс будет работать с диском_

    Параметры запуска:


         -p    <---- PID процесса
         -c 1 <---- _Класс планирования реального времени, наивысший приоритет. Активируется с root доступом_
         -n [0-7], _позволяет указать приоритет ввода/вывода (0-наивысший ) Процессы с одинаковыми приоритетами получают равные кванты времени для осуществления доступа к диску._
         -с 2 <---- _Стандартный класс планирования операций ввода/вывода. Приоритет ввода/вывода процесса по умолчани_
         -n [0-7], _позволяет указать приоритет ввода/вывода (0-наивысший ) Процессы с одинаковыми приоритетами получают равные кванты времени для осуществления доступа к диску._
         -с 3 <---- _Процесс будет работать с диском только тогда, когда другие процессы не будут работать с ним в течение определенного времени._
         -n      Не используется
<details>
    <summary>Примеры команды ionice </summary>   

        time sudo ionice -c 1 -n 0  dd if=/dev/zero of=/tmp/test.img bs=2000 count=1M &   <---- Запуск в bg, в скрипте
        time sudo ionice -c 3 dd if=/dev/zero of=/tmp/test2.img bs=2000 count=1M &         <---- Запуск в bg, в скрипте
        ionice -p 21420                                                                                                             <---- Получение информации о классе планирования и приоритете ввода/вывода процесса
        ionice -c 3  -p 21420                                                                                                     <---- Изменение класса планирования и приоритета ввода/вывода существующего процесса
</details>

___


*   **ls                :**  _Просмотр директории_

    ключ -d  <---- Отобразить только сами имена директорий, а не содержимое.
>           ls -d /proc/+([0-9])/ - вывести имена каталогов в директории proc, имя которых цифры.

___


*   **lnav              :**  _Log File Navigator, lnav_, является расширенным средством просмотра файлов журналов, которое использует любую     семантическую информацию, которую можно почерпнуть из просматриваемых файлов, таких как отметки времени и уровни журналов.

    Ставится из epel репозитория,

      dnf install lnav




___

*   **loginctl              :** _Кто является владельцем сеанса_

    Параметры запуска:


    [root@secsrv log]# loginctl                                                                       
   SESSION        UID USER             SEAT                                                           
         8       1001 tester                                                                     
         6       1000 vagrant                                                                    

         2 sessions listed.

___



*   **nice           :** _Установка приоритета выполнения процесса от '19' - наименьший приоритет, '-20' - наивысший приоритет_

    Параметры запуска:

    -n      <---- Запуск с определённым приоритетом, больше 0 не требуют root прав.


<details>
    <summary>Примеры команды nice </summary>       

            sudo nice -n -10 tar -czf nice_higt.tar.bz2 /usr/src/

 </details>   

*   **nohup         :** _Cохранить запущенные процессы после прекращения работы терминала_

    Параметры запуска:

    Для запуска команды в фоновом режиме нужно написать команду в виде:

        $ nohup command &



___


*   **renice            :** _Изменение приоритета процесса

     Параметры запуска:

___


*   **paste         :** _Объединяет два файла в идин, или преобразует строки расположенные в колонку,  в одну строку.  С ключом -d добавить разделитель полей ( например - ;)_

___


*   **source         :**  _Команда source позволяет выполнить скрипт в текущем командном интерпретаторе, а это значит, что всё переменные и функции, добавленные в этом скрипте, будут доступны также и в оболочке после его завершения. По умолчанию для выполнения каждого скрипта запускается отдельная оболочка bash, хранящая все его переменные и функции. После завершения скрипта всё это удаляется вместе с оболочкой._

*   **sort              :** _Команда сортировки_

    <details>
        <summary>Oсновные опции и примеры утилиты sort. </summary>

        -b - не учитывать пробелы
        -d - использовать для сортировки только буквы и цифры
        -i - сортировать только по ASCII символах
        -n - сортировка строк linux по числовому значению
        -r - сортировать в обратном порядке
        -с - проверить был ли отсортирован файл
        -o - вывести результат в файл
        -u - игнорировать повторяющиеся строки
        -m - объединение ранее отсортированных файлов
        -k - указать поле по которому нужно сортировать строки, если не задано, сортировка выполняется по всей строке.
        -f - использовать в качестве разделителя полей ваш символ вместо пробела.
        -g - глобальная сортировка, т.е 1,2,3,4 а не 1,10,11,2,20,21

    >    sort --field-separator=/ -k 3 -g    <---- Сортировка вывода, где разделитель полей "/"


</details>

___


*   **top                 :**   _Просмотр параметров процессов в интерактивном режиме

> man top - ман по параметрам и ключам утилиты ps

[Ссылка на страничку с основными ключами работы](https://zalinux.ru/?p=1811&PageSpeed=noscript)

___


*   **timedatectl    :** _Управление системным временем и датой._

    Параметры запуска:

<details>
    <summary>Примеры команды timedatectl </summary>

      Установка локального времени системы напрямую:
        timedatectl set-time {{"yyyy-MM-dd hh:mm:ss"}}

      Просмотр доступных временных зон:
        timedatectl list-timezones

      Смена временной зоны:
        timedatectl set-timezone {{timezone}}

</details>

___


*   **AWK           :** _AWK_

>   **Работает со строкой**
>
>   **“pattern { action statements }“** _ОБЩИЙ СИНТАКСИС КОМАНДЫ AWK_


<details>
    <summary>Потоковый текстовый редактор "awk"   </summary>


*   **Специальные символы :**

>   Существуют некоторые специальные символы, или метасимволы, использование которых в шаблоне требует особого подхода. Вот они:

        .*[]^${}\+?|()

   _Примеры использования в шаблонах:_

        awk '/\$/{print $0}' myfile <---- Экранируем "$"

        awk '/\\/{print $0}' myfile <---- Экранируем "\" обратный слеш

        awk '/\//{print $0}' myfile <---- Экранируем "/" прямой слеш

___

*   **Якорные символы   :**

>   Существуют два специальных символа для привязки шаблона к началу или к концу текстовой строки.

        ^   <---- Символ ^ предназначен для поиска шаблона в начале строки,
        $   <---- Символ $ предназначен для поиска шаблона в конце строки

---

*   **Классы символов   :**

>   Выполнить поиск любого символа из заданного набора

        [] - Для описания класса символов используются квадратные скобки

   _Примеры использования в шаблонах:_

        awk '/[oi]th/{print $0}' myfile

        awk '/[Tt]his is a test/{print $0}' myfile
___


*   **Диапазоны символов    :**

>   В символьных классах можно описывать диапазоны символов, используя тире:

        awk '/[e-p]st/{print $0}' myfile <----

        awk '/[0-9][0-9][0-9]/' myfile   <---- Диапазоны можно создавать и из чисел

        awk '/[a-fm-z]st/{print $0}' myfile <---- В класс символов могут входить несколько диапазонов



</details>

___


*   **SED           :** _SED_

>   **Работает со строкой**
>
>   **_[ addr [ ,addr ] ] cmd '[ args ]'_**  _ОБЩИЙ СИНТАКСИС КОМАНДЫ AWK_


<details>
    <summary>Потоковый текстовый редактор "sed" </summary>

**параметр "d" <-- _удалить строку_**

<details>
            <summary>Пример </summary>

    who | sed -e '10 d'
    who | sed -e '2,4 d'
    who | sed -e '/pts/ d'

</details>



**ключ "-e"     :**     <----_Добавление скрипта в исполняемые команды_( это скрипт -> 's/#.*//;/^$/d' )

    <details>
            <summary>Пример </summary>

Для удаления всех закомментированных строк (например начинающихся с #), а так же всех пустых строк выполните:

    sed -e 's/#.*//;/^$/d' testfile.txt     <----  Вначале заменяем все строки с коментариями на пустые, а потом пустые строки удаляем.
                                                            Аргументы для замены и удаления разделяются ";" - 's/#.*//;/^$/d' Хотя можно было сразу удалять
                                                             все строки с коментариями (sed -e '/^#/d' test.log > test1.log).

    (sed -e '/^#/d' test.log > test1.log)  <---- Удаление из вывода строк начинающихся с символа "#", т.е. коментарии в файле. Вывод перенаправим в файл test1.log
    sed -e '/^#/!d' test.log > test1.log    <---- Удаление из выводы строк, которые НЕ начинаются с "#". Вывод перенаправим в файл test1.log

      </details>

**параметр "s"  :**     <---- _Замена по регулярному выражению_

    who | sed -e 's/USER/user/g'     <--- '/s"что"/"на что" "/g' <- глобальное использование ("/g") работает по всему файлу, если указан файл.
    sed '/шаблон/s"что"/"на что"/g' /etc/postfix/main.cf   <---- Замена значения по шаблону в потоке или файле.


**ключ "-i"        :**     <----  _Производит  изменения сразу в файле_

Производит  изменения сразу в файле. Можно задать (sed -i.bak), тогда будет создаваться резервная копия изменяемого файла  
    Пример:

    sed -i.bak '/inet_protocols/s/inet_protocols = all/inet_protocols = ipv4/' /etc/postfix/main.cf

**Вставка текста (IP адреса клиентов подлежащих анализу:) в файл  (report_stat_file.txt) перед второй строкой (параметр 2i)     :**

    Пример:

    sed -i '2i IP адреса клиентов подлежащих анализу:' ${filedata}report_stat_file.txt

**Вставка текста ( ip_analise) в файл  (report_stat_file.txt)  после второй строки  (параметр 2r)     :**

    Пример:

    sed -i '2r ip_analise' report_stat_file.txt

**Вставка строки после нужной     :**

    sed -i '/"образец поиска"/a "что вставить после найденного образца"' /path/filename

    sed -i '/\# access_log  \/var\/log\/nginx\/access.log  main\;/a \\t access_log syslog:server\=192.168.10.11:35514,facility\=local6,tag\=nginx_acces,severity\=info combined\;
    ' /etc/nginx/nginx.conf

    где "\\t" - вставка пробела


При выполнении команды «sed -i» если вы редактируете не сам файл, а ссылку на него, файл ссылки будет удален и на его месте появится самый обычный файл. Чтобы этого не произошло, вам следует пользоваться опцией «—follow-symlinks»

    sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux



</details>


##          2.5 Регулярные выражения

[Сайт regex101.com  для составления и проверки регулярных выражений ](https://regex101.com/)

[Сайт regexr.com  для составления и проверки регулярных выражений ](https://regexr.com/)





<details>
    <summary>Сайт для составления и проверки регулярных выражений   </summary>

</details>

___

##          2.6 Массивы

**Способы инициализации массива         :**

    files = $(ls) - считывается строка
    array=('first element' 'second element' 'third element')
    array=([3]='fourth element' [4]='fifth element')
    echo ${array[2]}
    IFS=$'\n'; echo "${array[*]}" <---- IFS - разделитель полей массива
    declare -A array              <---- Объявление переменной как массив
    array[first]='First element'  <---- Массив с текстовым индексом "first" т.е. массив проиндексирован текстовым индексом
    array[second]='Second element'
    array[0]='first element'
    array[1]='second element'

<details>
        <summary>Пример: цикл по элементам массива</summary>    
    arr=(a b c d e f)
    for i in "${arr[@]}"
    do
    echo "$i"
    done
</details>

<details>
        <summary>Пример: цикл "while" по  количеству элементов массива.  </summary>
    i=0
    arr=(a b c d e f)
    while (( $i < ${#arr[@]} ))  <---- _**Количество ${#arr[@]}  элементов в массиве**_
    do
    echo "${arr[$i]}"  <---- Выводим значение массива, на основании его цифрового индекса
    (( i++ ))
    done
</details>

<details>
        <summary>Пример: цикл "for"  по  количеству элементов массива. </summary>
    arr=(a b c d e f)
    for (( i=0;i<${#arr[@]};i++ )) <---- _**Количество ${#arr[@]}  элементов в массиве и вычисление индекса массива**_
    do
    echo "${arr[$i]}"
    done
</details>

<details>
        <summary>Пример: цикл "for" заполнение массива значениями.</summary>
     s=0
     for i in $(ls ./)
        do
            array+=($i)     <----- _**Заполняем массив значениями (ls ./), индексы берутся автоматически, начиная с 0**_
            array=( $(ls) ) <----- _**Или так заполнить массив, значениями выполнения программы ls в текущей директории**_
            echo "${arr[$s]}"
            (( s++ ))
        done
</details>    



**Таблица работы с массивами в BASH**

<table>
  <tr>
    <th>Синтаксическая конструкция</th>
    <th>Описание</th>
  </tr>
  <tr>
    <td>arr=(1 2 3)</td>
    <td>Инициализация массива</td>
  </tr>
  <tr>
    <td>${arr[2]}</td>
    <td>Получение третьего элемента массива</td>
   </tr>
   <tr>
        <td>${arr[@]}</td>
        <td>Получение всех элементов массива</td>
   </tr>

   <tr>
        <td>${!arr[@]}</td>
        <td>Получение индексов массива</td>
   </tr>

   <tr>
        <td>${#arr[@]}</td>
        <td>Вычисление размера, количество элементов массива. </td>
   </tr>

   <tr>
        <td>arr[0]=3</td>
        <td>Перезапись первого элемента массива</td>
   </tr>

   <tr>
        <td>arr+=(4)</td>
        <td>Присоединение к массиву значения</td>
   </tr>

   <tr>
        <td>str=$(ls)</td>
        <td>Сохранение вывода команды ls в виде строки</td>
   </tr>

   <tr>
        <td>arr=( $(ls) )</td>
        <td>Сохранение вывода команды ls в виде массива имён файлов</td>
   </tr>

   <tr>
        <td>${arr[@]:s:n}</td>
        <td>Получение элементов массива начиная с элемента с индексом s до элемента с индексом s+(n-1)</td>
   </tr>

</table>


___

##          2.7 Условия проверки

**Условия для строк и чисел:**

    -z # строка пуста
    -n # строка не пуста
    =, (==) # строки равны
    != # строки не равны
    -eq # число равно
    -ne # число не равно
    -lt,(< ) # число меньше
    -le,(<=) # число меньше или равно
    -gt,(>) # число больше
    -ge,(>=) # число больше или равно
    ! # отрицание логического выражения
    -a,(&&) # логическое «И»
    -o,(||) # логическое «ИЛИ»

**Проверки для файлов:**

    [ -e FILE ] — файл существует
    [ -d FILE ] — это директория
    [ -f FILE ] — это обычный файл
    [ -s FILE ] — размер ненулевой
    [ -r FILE ] — доступен для чтения
    [ -w FILE ] — доступен для записи
    [ -x FILE ] — исполняемый

___
___


#                                                               3. Программирование в  Shell

##          3.1 Bash



*         _**переименование файла**_ -  *mv $logfile "$(ls $logfile | cut -f 1 -d .).log1"*  Когда имя файла задано переменной, вырезать первое поле с именем ($(ls $logfile | cut -f 1 -d .)) и сформировать новое имя . Пример для использования программы "cut"
