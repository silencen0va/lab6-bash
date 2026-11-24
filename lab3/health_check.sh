#!/bin/bash
REPORT="health_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"
CPU_LIMIT=85
RAM_LIMIT=80
DISK_LIMIT=85
SERVICES=(cron rsyslog ufw)

{
echo "=== Отчёт о состоянии сервера ==="
echo "Сервер:   $(hostname)"
echo "Дата:     $(date '+%Y-%m-%d %H:%M:%S')"
echo "Аптайм:   $(uptime -p)"
echo "ОС:       $(. /etc/os-release; echo "$PRETTY_NAME")"
echo "Ядро:     $(uname -r)"
echo
echo "--- Сеть ---"
echo "IP-адрес: $(hostname -I | awk '{print $1}')"
echo "Шлюз:     $(ip route | awk '/default/ {print $3; exit}')"
echo "DNS:      $(awk '/^nameserver/ {print $2}' /etc/resolv.conf | tr '\n' ' ')"
echo
echo "--- Ресурсы ---"
CPU=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')
RAM=$(free | awk '/Mem:/ {printf "%d", $3/$2*100}')
DISK=$(df / | awk 'NR==2 {gsub("%", "", $5); print $5}')
echo "CPU:  ${CPU}%"
echo "RAM:  ${RAM}%"
echo "Disk: ${DISK}%"
[ "$CPU" -ge "$CPU_LIMIT" ] && echo "ВНИМАНИЕ: высокая загрузка CPU"
[ "$RAM" -ge "$RAM_LIMIT" ] && echo "ВНИМАНИЕ: мало свободной памяти"
[ "$DISK" -ge "$DISK_LIMIT" ] && echo "ВНИМАНИЕ: диск почти заполнен"
echo
echo "--- Топ-5 процессов по памяти ---"
ps -eo pid,user,%mem,comm --sort=-%mem | head -6
echo
echo "--- Состояние служб ---"
for service in "${SERVICES[@]}"; do
    echo "$service: $(systemctl is-active "$service" 2>/dev/null || true)"
done
echo
echo "--- Обычные пользователи (UID >= 1000) ---"
awk -F: '$3 >= 1000 && $3 < 65534 {print $1 " (UID " $3 ")"}' /etc/passwd
echo
echo "--- Группа sudo ---"
getent group sudo
} | tee "$REPORT"

echo
echo "Отчёт сохранён: $REPORT"
