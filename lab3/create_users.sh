#!/bin/bash
FILE="$1"

if [ "$EUID" -ne 0 ]; then
    echo "Запустите скрипт через sudo"
    exit 1
fi
if [ ! -f "$FILE" ]; then
    echo "Файл $FILE не найден"
    exit 1
fi

tail -n +2 "$FILE" | while IFS=',' read -r login fullname dept; do
    group="dept_${dept}"
    getent group "$group" >/dev/null || groupadd "$group"
    if id "$login" &>/dev/null; then
        echo "[ПРОПУСК] $login уже существует"
        continue
    fi
    useradd -m -s /bin/bash -c "$fullname" -G "$group" "$login"
    echo "$login:Temp_$(openssl rand -hex 4)" | chpasswd
    chage -d 0 "$login"
    echo "[OK] $login ($fullname) -> группа $group"
done
