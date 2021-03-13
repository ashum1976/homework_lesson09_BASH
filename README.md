

#                                                               1. Теория BASH

##          1.1 Hot keys BASH


1.  **Ctrl+a Ctrl+e                 :** <----- *Возврат курсорав начало строки, переход курсора в конец строки*

2.  **Alt+f Alt+b                    :**  <----- _Перемещение на слово вперёд, премещение на слово назад_

3.  **Ctrl+w                           :**   <---- _Ctrl+w - удаляет слово до курсора (при этом копируя его в буфер обмена)_

-.  **Alt+d                              :** <----- _Удаляет слово после курсора_   

4.  **Ctrl+u                            :** <---- _Удаляет всю строку до курсора_

5.  **Ctrl+k                            :** <----   _Удаляет всю строку после курсора_

-.  **Ctrl+r                            :**   <---- _Поиск по строке
        
        Ctrl+j                     : <----   Закончить поиск по истории
        Ctrl+g                     : <----   Закончить поиск и вернуть строку к прежнему состоянию


##          1.2 Перенаправления в BASH

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

    cat << EOF > myscript.sh
    #!/bin/bash
    echo “Hello Linux!!!”
    exit 0
    EOF
</details>

##                                          1.3 Переменные в BASH


**set              :**    <---- _установка атрибутов переменных_

**declare       :**    <---- _установка значений переменных и управление атрибутами переменных_ 


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





##          1.4 Команды в BASH

[ Ссылка на основные команды BASH ]( https://losst.ru/osnovnye-komandy-bash )   

[ Ссылка на команды терминала linux ](https://losst.ru/komandy-terminala-linux)


*   **export         :**  _Все объявленные с помощью нее переменные экспортируются во внешнее окружение среды и будут доступны всем скриптам и программам. С помощью опции -p вы можете посмотреть экспортированные на данный момент переменные._

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

*   **find              :** _Find - это одна из наиболее важных и часто используемых утилит системы Linux. Это команда для поиска файлов и каталогов на основе специальных условий. Ее можно использовать в различных обстоятельствах, например, для поиска файлов по разрешениям, владельцам, группам, типу, размеру и другим подобным критериям._

<details> 
    <summary>Примеры команды find </summary>
        
    Изменение атрибутов файлов в папках
        
    find ./ -type f -exec chmod -X '{}' \;  <----- Изменить атрибуты файлов ( -type f), убрать значение, что этот файл исполняемый, если он таковым не является
    
</details>


*   **source         :**  _Команда source позволяет выполнить скрипт в текущем командном интерпретаторе, а это значит, что всё переменные и функции, добавленные в этом скрипте, будут доступны также и в оболочке после его завершения. По умолчанию для выполнения каждого скрипта запускается отдельная оболочка bash, хранящая все его переменные и функции. После завершения скрипта всё это удаляется вместе с оболочкой._


*   **awk           :** _AWK_

>   **Работает со строкой**
>
>   **“pattern { action statements }“**  _ОБЩИЙ СИНТАКСИС КОМАНДЫ AWK_

*   **Специальные символы :**

>   Существуют некоторые специальные символы, или метасимволы, использование которых в шаблоне требует особого подхода. Вот они:
    
        .*[]^${}\+?|()


        
<details> 
    <summary>Потоковый текстовый редактор "awk"   </summary>
    
</details>



*   **sed           :** _SED_

>   **Работает со строкой**
>
>   **_[ addr [ ,addr ] ] cmd [ args ]**    _ОБЩИЙ СИНТАКСИС КОМАНДЫ AWK_





<details> 
    <summary>Потоковый текстовый редактор "sed" </summary>
        
d <-- _удалить строку_

    who | sed -e '10 d'
    who | sed -e '2,4 d'
    who | sed -e '/pts/ d'

s <-- _замена по регулярному выражению_
    
    who | sed -e "s/USER/user/g"    <--- /s"что"/"на что" "/g - глобальное использование"  


    
    
</details>



##          1.5 Регулярные выражения

[Сайт regex101.com  для составления и проверки регулярных выражений ](https://regex101.com/)

[Сайт regexr.com  для составления и проверки регулярных выражений ](https://regexr.com/)





<details> 
    <summary>Сайт для составления и проверки регулярных выражений   </summary>


##          1.6 Массивы

**Способы инициализации массива         :**

    files = $(ls) - считывается строка
    array=('first element' 'second element' 'third element')
    array=([3]='fourth element' [4]='fifth element')
    array[0]='first element'
    array[1]='second element'
    echo ${array[2]}
    IFS=$'\n'; echo "${array[*]}" <---- IFS - разделитель полей массива
    declare -A array              <---- Объявление переменной как массив
    array[first]='First element'  <---- Массив с текстовым индексом "first" т.е. массив проиндексирован текстовым индексом
    array[second]='Second element'

    
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
        <td>Вычисление размера массива</td>
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



    
##          1.7 Условия проверки

**Условия для строк и чисел:**

    -z # строка пуста
    -n # строка не пуста
    =, (==) # строки равны
    != # строки не равны
    -eq # равно
    -ne # не равно
    -lt,(< ) # меньше
    -le,(<=) # меньше или равно
    -gt,(>) # больше
    -ge,(>=) # больше или равно
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

