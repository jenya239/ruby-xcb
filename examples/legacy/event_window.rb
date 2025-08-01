#!/usr/bin/env ruby

require_relative '../lib/xcb'

puts "=== Окно с обработкой событий XCB ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

# Получение screen
setup = XCB.xcb_get_setup(conn)
iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(iter[:data])

root = screen[:root]
visual = screen[:root_visual]
white_pixel = screen[:white_pixel]

puts "✅ Подключено к экрану: #{screen_ptr.read_int}"

# Создание окна
window_id = XCB.xcb_generate_id(conn)
puts "✅ ID окна: #{window_id}"

# Подготовка атрибутов окна с маской событий
value_mask = XCB::XCB_CW_BACK_PIXEL | XCB::XCB_CW_EVENT_MASK
value_list = FFI::MemoryPointer.new(:uint32, 2)
event_mask = XCB::XCB_EVENT_MASK_EXPOSURE | 
             XCB::XCB_EVENT_MASK_KEY_PRESS | 
             XCB::XCB_EVENT_MASK_BUTTON_PRESS |
             XCB::XCB_EVENT_MASK_STRUCTURE_NOTIFY
value_list.write_array_of_uint32([white_pixel, event_mask])

# Создание окна
XCB.xcb_create_window(
  conn, XCB::XCB_COPY_FROM_PARENT, window_id, root,
  200, 200, 500, 400, 2,
  XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT, visual,
  value_mask, value_list
)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

puts "✅ Окно создано с обработкой событий!"
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