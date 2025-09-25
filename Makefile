include $(TOPDIR)/rules.mk

PKG_NAME:=telegramopenwrt-bot
# Версия берётся из git-тега; если тегов нет — подставится 0.0.0+<shortrev>
PKG_VERSION:=$(shell (git describe --tags --always --dirty 2>/dev/null || echo 0.0.0) | sed 's/^v//')
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Mikhail <you@example.com>

include $(INCLUDE_DIR)/package.mk

define Package/telegramopenwrt-bot
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Telegram OpenWrt Bot (minimal: reboot + get_uptime)
  DEPENDS:=+bash +curl +ca-bundle
  # по желанию: +openssl-util или +libustream-openssl, если твои скрипты это используют
endef

# Сохраняем UCI-конфиг при обновлениях
define Package/telegramopenwrt-bot/conffiles
/etc/config/telegramopenwrt
endef

# Ничего не компилируем — это набор скриптов
define Build/Compile
endef

# КОПИРУЕМ ГОТОВЫЕ ФАЙЛЫ ИЗ ./files/ В ФС ПАКЕТА
define Package/telegramopenwrt-bot/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_DIR) $(1)/usr/lib/telegramopenwrt/plugins

	# конфиг UCI как конфиг-файл
	$(INSTALL_CONF) ./files/etc/config/telegramopenwrt $(1)/etc/config/telegramopenwrt

	# init-скрипт и бинарники бота
	$(INSTALL_BIN) ./files/etc/init.d/telegram_bot $(1)/etc/init.d/telegram_bot
	$(INSTALL_BIN) ./files/sbin/telebot $(1)/sbin/telebot
	$(INSTALL_BIN) ./files/sbin/telegram_bot $(1)/sbin/telegram_bot
	$(INSTALL_BIN) ./files/sbin/telegram_sender $(1)/sbin/telegram_sender

	# плагины (только нужные)
	$(INSTALL_BIN) ./files/usr/lib/telegramopenwrt/plugins/get_uptime $(1)/usr/lib/telegramopenwrt/plugins/get_uptime
	$(INSTALL_BIN) ./files/usr/lib/telegramopenwrt/plugins/reboot $(1)/usr/lib/telegramopenwrt/plugins/reboot
endef

# postinst: авто-enable и мягкий рестарт сервиса после установки на реальную систему
define Package/telegramopenwrt-bot/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
# гарантируем права на исполняемые файлы (на случай, если забыли в репо)
chmod +x /etc/init.d/telegram_bot /sbin/telebot /sbin/telegram_bot /sbin/telegram_sender \
  /usr/lib/telegramopenwrt/plugins/get_uptime /usr/lib/telegramopenwrt/plugins/reboot 2>/dev/null || true
/etc/init.d/telegram_bot enable >/dev/null 2>&1 || true
/etc/init.d/telegram_bot restart >/dev/null 2>&1 || true
exit 0
endef

# prerm: останавливаем и отключаем сервис при удалении
define Package/telegramopenwrt-bot/prerm
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
/etc/init.d/telegram_bot stop >/dev/null 2>&1 || true
/etc/init.d/telegram_bot disable >/dev/null 2>&1 || true
exit 0
endef

$(eval $(call BuildPackage,telegramopenwrt-bot))
