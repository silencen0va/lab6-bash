#!/bin/bash
LOG="${1:-auth_sample.log}"
LIMIT=3

if [ ! -f "$LOG" ]; then
    echo "Файл $LOG не найден" >&2
    exit 1
fi

echo "Всего неудачных попыток входа: $(grep -c 'Failed password' "$LOG")"
echo "Успешных входов: $(grep -c 'Accepted' "$LOG")"
echo
echo "Топ IP-адресов по неудачным попыткам:"
grep 'Failed password' "$LOG" | grep -oE 'from [0-9.]+' | awk '{print $2}' | sort | uniq -c | sort -rn
echo
echo "Попытки входа под несуществующими пользователями:"
grep 'invalid user' "$LOG" | awk '{for (i=1; i<=NF; i++) if ($i=="user") print $(i+1)}' | sort -u
echo
echo "Кандидаты на блокировку (неудачных попыток не менее $LIMIT):"
grep 'Failed password' "$LOG" | grep -oE 'from [0-9.]+' | awk '{print $2}' | sort | uniq -c | awk -v limit="$LIMIT" '$1 >= limit {print $2 " (" $1 ")"}'
echo
echo "Попытки sudo без прав:"
grep 'NOT in sudoers' "$LOG" || true
