#!/bin/sh

# Путь к конфигурационному файлу
CONFIG_FILE="/var/ndnproxymain.conf"

# Проверяем, был ли передан домен при запуске
if [ -n "$1" ]; then
    # Используем переданный домен
    DOMAINS="$1"
else
    # Используем список доменов по умолчанию
    DOMAINS="
instagram.com
youtube.com
"
fi

# Получаем список DNS-серверов и портов
dns_servers=$(cat "$CONFIG_FILE" | grep dns_server | awk '{print $3}')

# Проходим по каждому DNS-серверу
for dns in $dns_servers; do
    # Извлекаем IP и порт
    ip=$(echo "$dns" | cut -d':' -f1)
    port=$(echo "$dns" | cut -d':' -f2)

    # Проходим по каждому домену (или по переданному домену)
    for domain in $DOMAINS; do
        # Выполняем DNS-запрос и фильтруем вывод для получения нужной информации
        result=$(dig @$ip -p $port $domain A | grep -i 'in')
        
        # Извлекаем IP из результата
        ip_address=$(echo "$result" | awk '{print $NF}' | tail -n 1)
        
        # Проверяем, был ли найден IP-адрес
        if [ -n "$ip_address" ]; then
            # Тестируем IP на пинг с 1 запросом и ограничиваем время ожидания в 1 секунду
            ping -c 1 -W 1 $ip_address >/dev/null 2>&1
            ping_status=$?
            if [ $ping_status -eq 0 ]; then
                ping_result="yes"
            else
                ping_result="no"
            fi
            # Выводим информацию
            echo "$ip:$port $domain $ip_address $ping_result"
        else
            echo "$ip:$port $domain Not Found no"
        fi
    done
done

