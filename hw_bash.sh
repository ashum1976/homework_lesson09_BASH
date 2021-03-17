#!/usr/bin/env bash

# log_all_string.txt                <----- Промежуточный файл, создаваемый в процессе работы анализатора, хранит число всех строк в анализируемом файле
# log_date_save_last.txt       <---- Файл создаваемый для хранения значения даты/времени последней строки анализируемого файла. Используется для определения точки старта, при повторном запуске анализатора.
#report_stat_file.txt              <---- Формируемый файл отчёта, отправляемый пользователю

filelog=./analise_log_file.txt
filedata=/var/tmp/log/


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
                                    
                                    #Переменная, для вставки временного интервала в письмо для root-a
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
                                    
                                    #Создаём две переменных, для вывода временного интервала, в котором будет отрабатывать скрипт, по проверке лог файла.
                                    log_date_first=$(cat ${filedata}log_date_save_last.txt)
                                    log_date_last=$(tail -n1 ${filelog} | awk -F" " '{print $4}' | tr -d [)
                                    
                                    #Переменная, для вставки временного интервала в письмо для root-a
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

#Создадим два массива ( очень массивы именно для этого подходят, чтобы задать и обрабатывать много значений (IP или число появлений IP адрессов в файле) полученных от работы потокового редактора sed или awk )

array_ip=( $(echo $ip_sort) )           # <---- Массив iP адресов
array_num=( $(echo $ip_num) )       # <---- Массив количества появлений IP адрессов

i=0
while (( $i < ${#array_ip[@]} ))
        do
            
            if [[ ${array_num[$i]} -ge 5 ]]
                then
                    
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

#Отправляем пользователю root почту с отчётом 
mutt -s "Анализ лог файла ${filelog}, за период ${mail_log_time}" vagrant@localhost < ${filedata}report_stat_file.txt && rm ${filedata}report_stat_file.txt



