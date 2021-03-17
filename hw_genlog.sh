#!/usr/bin/env bash

#logfile_tmp=$(ls access-*.log1 2>/dev/null)
#Переменная содержащая эталонный лог-файл (access-*.log лежит в папке пользователя vagrant), из которого будем генерировать рабочий лог-файл (analise_log_file.txt) для анализатора
logfile=$(ls access-*.log 2>/dev/null)

if [[  -e "$logfile" && ! -e  ./analise_log_file.txt ]]

    then
            head -n 5 $logfile > ./analise_log_file.txt
            tail -n +6  $logfile > ./var_log_file             #<---- Промежуточный файл для создания рабочего лог-файла (analise_log_file)
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
