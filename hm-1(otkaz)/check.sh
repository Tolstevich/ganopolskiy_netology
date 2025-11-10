#!/bin/bash

# Проверяю порт 80
if nc -z -w 3 127.0.0.1 80; then
    # Проверяю есть ли индекс файл
    if [ -f /var/www/html/index.html ]; then
        echo "OK: Port 80 and index.html are available"
        exit 0
    else
        echo "ERROR: index.html not found"
        exit 1
    fi
else
    echo "ERROR: Port 80 is not accessible"
    exit 1
fi
