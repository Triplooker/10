#!/bin/bash

while true; do
    echo "Остановка всех контейнеров..."
    docker stop $(docker ps -aq) || true

    echo "Очистка логов Docker..."
    find /var/lib/docker/containers/ -name "*-json.log" -exec truncate -s 0 {} \;

    echo "Удаление неиспользуемых ресурсов Docker..."
    docker system prune -af --volumes || true

    echo "Перезапуск службы Docker..."
    systemctl restart docker

    echo "Ожидание запуска Docker..."
    sleep 10

    echo "Запуск валидаторов..."
    for validator in validator_*; do
        if [ -d "$validator" ]; then
            number=${validator#validator_}
            (cd "$validator" && docker run -d --env-file validator.env --name elixir-validator-$number -v "$(pwd):/app/data" -p $((17690 + number)):17690 --restart unless-stopped elixirprotocol/validator:v3) || echo "Не удалось запустить $validator"
        fi
    done

    echo "Проверка статуса Docker и контейнеров..."
    systemctl status docker
    docker ps

    echo "Проверка свободного места на диске..."
    df -h

    sleep 36000
done