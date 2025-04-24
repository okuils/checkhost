#!/bin/bash

# Принудительно устанавливаем английский язык для парсинга команд
export LC_ALL=C

# Функции вывода информации
show_help() {
    echo "Использование: $0 [ПАРАМЕТРЫ]"
    echo "Параметры:"
    echo "  --host      Показать всю информацию о хосте"
    echo "  --cpu       Информация о процессоре"
    echo "  --ram       Информация об оперативной памяти"
    echo "  --disk      Информация о дисках"
    echo "  --load      Загрузка системы"
    echo "  --time      Текущее время"
    echo "  --uptime    Время работы системы"
    echo "  --net       Сетевые интерфейсы"
    echo "  --ports     Слушаемые порты"
    echo "  --user      Информация о пользователях"
    echo "  --help      Эта справка"
    echo ""
    echo "Примеры:"
    echo "  $0 --cpu --ram       # Показать CPU и RAM"
    echo "  $0 --host            # Вся информация о системе"
    echo "  $0 --user            # Информация о пользователях"
}

show_cpu() {
    echo -e "\n▓▓▓ ПРОЦЕССОР ▓▓▓"
    echo "▪ Ядер процессора: $(nproc)"
    echo "▪ Модель: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
}

show_ram() {
    echo -e "\n▓▓▓ ОПЕРАТИВНАЯ ПАМЯТЬ ▓▓▓"
    free -h | awk '
        /Mem:/ {print "▪ Всего: " $2 "\n▪ Используется: " $3 "\n▪ Доступно: " $7}'
}

show_disk() {
    echo -e "\n▓▓▓ ДИСКИ ▓▓▓"
    echo "▌Файловые системы:"
    df -h | awk '
        NR>1 {printf "▪ %-15s %-8s %-8s %-8s (%s)\n", $1, $2, $3, $4, $5}'
    
    echo -e "\n▌Ошибки дисков:"
    dmesg | grep -i 'error' | grep 'sd\|disk' | tail -n 3 | sed 's/.*/▪ &/' || echo "▪ Нет критических ошибок"
}

show_load() {
    echo -e "\n▓▓▓ ЗАГРУЗКА СИСТЕМЫ ▓▓▓"
    uptime | awk -F': ' '{print "▪ " $2}'
}

show_time() {
    echo -e "\n▓▓▓ ТЕКУЩЕЕ ВРЕМЯ ▓▓▓"
    date "+▪ %d/%m/%Y %H:%M:%S"
}

show_uptime() {
    echo -e "\n▓▓▓ ВРЕМЯ РАБОТЫ ▓▓▓"
    uptime -p | sed 's/up/▪ Система работает:/'
}

show_net() {
    echo -e "\n▓▓▓ СЕТЕВЫЕ ИНТЕРФЕЙСЫ ▓▓▓"
    echo "▌Активные интерфейсы:"
    ip -o link show | awk '$9 == "UP" {print "▪ " $2}' | sed 's/://'
    
    echo -e "\n▌IP-адреса:"
    ip -o -4 addr show | awk '{print "▪ " $2 " " $4}'
    
    echo -e "\n▌Статистика:"
    ip -s link | awk '
        /^[0-9]+:/ {
            interface = $2
            getline
            rx = $1
            tx = $6
            printf "▪ %-10s Прием: %-10s Передача: %s\n", interface, rx, tx
        }'
}

show_ports() {
    echo -e "\n▓▓▓ СЛУШАЕМЫЕ ПОРТЫ ▓▓▓"
    ss -tuln | awk '
        /LISTEN/ {
            split($5, a, ":")
            printf "▪ %-5s %-15s\n", a[2], $1
        }' | sort -u
}

show_user_info() {
    echo -e "\n▓▓▓ ПОЛЬЗОВАТЕЛИ ▓▓▓"
    echo "▌Все пользователи:"
    cut -d: -f1 /etc/passwd | sort | column -x
    
    echo -e "\n▌Суперпользователи:"
    grep -E ':0:' /etc/passwd | cut -d: -f1 | column -x
    
    echo -e "\n▌Активные сессии:"
    who | awk '{print "▪ " $1 " (" $2 ")"}' | sort | uniq
}

# Парсинг аргументов
PARSED=$(getopt -o "" \
    -l "host,cpu,ram,disk,load,time,uptime,net,ports,user,help" \
    -n "$0" -- "$@")

eval set -- "$PARSED"

# Флаги отображения
SHOW_HOST=false
SHOW_CPU=false
SHOW_RAM=false
SHOW_DISK=false
SHOW_LOAD=false
SHOW_TIME=false 
SHOW_UPTIME=false
SHOW_NET=false
SHOW_PORTS=false
SHOW_USER=false

while true; do
    case "$1" in
        --host)   SHOW_HOST=true; shift ;;
        --cpu)    SHOW_CPU=true; shift ;;
        --ram)    SHOW_RAM=true; shift ;;
        --disk)   SHOW_DISK=true; shift ;;
        --load)   SHOW_LOAD=true; shift ;;
        --time)   SHOW_TIME=true; shift ;;
        --uptime) SHOW_UPTIME=true; shift ;;
        --net)    SHOW_NET=true; shift ;;
        --ports)  SHOW_PORTS=true; shift ;;
        --user)   SHOW_USER=true; shift ;;
        --help)   show_help; exit 0 ;;
        --)       shift; break ;;
        *)        echo "Ошибка: $1"; exit 1 ;;
    esac
done

# Если хоть один параметр хоста выбран, добавляем заголовок
if $SHOW_HOST || $SHOW_CPU || $SHOW_RAM || $SHOW_DISK || \
   $SHOW_LOAD || $SHOW_TIME || $SHOW_UPTIME || $SHOW_NET || $SHOW_PORTS; then
    echo "════════════════════════════════════════════════"
    echo "          СИСТЕМНАЯ ИНФОРМАЦИЯ"
    echo "════════════════════════════════════════════════"
fi

# Автоматически выбираем все параметры для --host
if $SHOW_HOST; then
    SHOW_CPU=true SHOW_RAM=true SHOW_DISK=true SHOW_LOAD=true 
    SHOW_TIME=true SHOW_UPTIME=true SHOW_NET=true SHOW_PORTS=true
fi

# Вывод выбранных разделов
$SHOW_CPU && show_cpu
$SHOW_RAM && show_ram
$SHOW_DISK && show_disk
$SHOW_LOAD && show_load
$SHOW_TIME && show_time
$SHOW_UPTIME && show_uptime
$SHOW_NET && show_net
$SHOW_PORTS && show_ports

# Вывод информации о пользователях
$SHOW_USER && show_user_info

# Если ничего не выбрано - показать справку
if [ $# -eq 0 ] && ! $SHOW_HOST && ! $SHOW_USER \
   && ! $SHOW_CPU && ! $SHOW_RAM && ! $SHOW_DISK \
   && ! $SHOW_LOAD && ! $SHOW_TIME && ! $SHOW_UPTIME \
   && ! $SHOW_NET && ! $SHOW_PORTS; then
    show_help
fi
