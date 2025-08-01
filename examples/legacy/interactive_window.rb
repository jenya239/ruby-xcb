#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Интерактивное окно XCB ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения к X серверу"
  puts "Выполните: export DISPLAY=:0"
  exit 1
end

puts "✅ Подключено к экрану: #{screen_ptr.read_int}"

# Создание окна
window_id = XCB.xcb_generate_id(conn)

# Создание окна с маской событий
event_mask = 0x8000 | 0x1 | 0x4 | 0x10  # Exposure | KeyPress | ButtonPress | StructureNotify

create_cookie = XCB.xcb_create_window(
  conn, 0, window_id, 1,
  100, 100,      # позиция
  400, 300,      # размер
  2,             # граница
  1, 0,          # класс, визуал
  0x800,         # маска событий
  nil
)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

puts "✅ Интерактивное окно создано!"
puts "📍 Позиция: (100, 100), Размер: 400x300"
puts "🎮 Кликайте по окну или нажимайте клавиши"
puts "❌ Закройте окно через оконный менеджер или Ctrl+C"

# Цикл обработки событий
begin
  loop do
    event = XCB.xcb_wait_for_event(conn)
    
    if event.null?
      puts "⚠️  Соединение закрыто"
      break
    end
    
    event_struct = XCB::GenericEvent.new(event)
    event_type = event_struct[:response_type] & 0x7F
    
    case event_type
    when 12  # Expose
      puts "🎨 Окно перерисовано"
    when 2   # KeyPress
      puts "⌨️  Нажата клавиша"
    when 4   # ButtonPress
      puts "🖱️  Нажата кнопка мыши"
    when 17  # DestroyNotify
      puts "🗑️  Окно уничтожено"
      break
    when 18  # UnmapNotify
      puts "👁️  Окно скрыто"
    when 19  # MapNotify
      puts "👀 Окно показано"
    else
      puts "📨 Событие типа: #{event_type}"
    end
    
    # Небольшая пауза
    sleep(0.1)
  end
rescue Interrupt
  puts "\n🛑 Прервано пользователем"
end

# Очистка
XCB.xcb_destroy_window(conn, window_id)
XCB.xcb_flush(conn)
XCB.xcb_disconnect(conn)
puts "✅ Ресурсы освобождены"