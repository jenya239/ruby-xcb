#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Создание рабочего окна XCB ==="

# Подключение к X серверу
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения к X серверу"
  puts "Убедитесь, что X сервер запущен и DISPLAY установлен"
  exit 1
end

screen_num = screen_ptr.read_int
puts "✅ Подключено к экрану: #{screen_num}"

# Получение setup и root window
setup = XCB.xcb_get_setup(conn)
if setup.null?
  puts "❌ Не удалось получить setup"
  XCB.xcb_disconnect(conn)
  exit 1
end

# Создание окна
window_id = XCB.xcb_generate_id(conn)
puts "✅ Сгенерирован ID окна: #{window_id}"

# Используем правильный root window (обычно 1 для первого экрана)
root_window = 1

# Создание окна с белым фоном
white = 0xFFFFFF
create_cookie = XCB.xcb_create_window(
  conn,           # соединение
  0,              # глубина (CopyFromParent)
  window_id,      # window id
  root_window,    # parent window (root)
  100, 100,       # x, y
  400, 300,       # width, height
  2,              # border width
  1,              # class (InputOutput)
  0,              # visual (CopyFromParent)
  0,              # value mask
  nil             # value list
)

puts "✅ Окно создано"

# Показ окна
map_cookie = XCB.xcb_map_window(conn, window_id)
puts "✅ Окно показано"

# Отправка команд
XCB.xcb_flush(conn)
puts "✅ Команды отправлены на сервер"

puts "\n🎉 Окно должно появиться на экране!"
puts "Нажмите Enter для закрытия окна..."

# Ожидание ввода пользователя
gets

# Скрытие и уничтожение окна
XCB.xcb_unmap_window(conn, window_id)
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)

# Отключение
XCB.xcb_disconnect(conn)
puts "✅ Окно закрыто и ресурсы освобождены"