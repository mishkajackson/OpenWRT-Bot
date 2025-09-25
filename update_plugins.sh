#!/bin/sh
set -e  # выход при ошибке

# Папка с плагинами
PLUGIN_DIR="/usr/lib/telegramopenwrt/plugins"

# Список файлов, которые нужно оставить
KEEP="
clash_reload
clash_stop
get_uptime
reboot
update_config
update_sub
clash_start
ctx
help
start
update_rules
"

echo "🔄 Обновление пакетов и установка unzip..."
opkg update
opkg install unzip

echo "⬇️ Скачивание архива репозитория..."
curl -L -o /root/repo.zip https://github.com/mishkajackson/OpenWRT-Bot/archive/refs/heads/master.zip

echo "📦 Распаковка..."
cd /root
unzip -o repo.zip

echo "📂 Копирование файлов в $PLUGIN_DIR..."
cp -f OpenWRT-Bot-master/usr/lib/telegramopenwrt/plugins/* "$PLUGIN_DIR/"

echo "⚙️ Выставление прав на исполнение..."
chmod +x "$PLUGIN_DIR"/*

echo "🧹 Удаление лишних файлов..."
for f in "$PLUGIN_DIR"/*; do
    # пропускаем директории
    [ -d "$f" ] && continue

    fname=$(basename "$f")
    keep_flag=0
    for k in $KEEP; do
        if [ "$fname" = "$k" ]; then
            keep_flag=1
            break
        fi
    done

    if [ $keep_flag -eq 0 ]; then
        rm -f "$f"
        echo "   ❌ Удалён: $fname"
    else
        echo "   ✅ Оставлен: $fname"
    fi
done


echo "🗑 Очистка временных файлов..."
rm -f /root/repo.zip
rm -rf /root/OpenWRT-Bot-master

echo "✅ Плагины обновлены и лишние удалены."
