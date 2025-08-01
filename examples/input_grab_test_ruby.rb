#!/usr/bin/env ruby
require_relative '../lib/xcb'

puts "=== Ruby XCB Input Grab Test ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения"
  exit 1
end

# Получение экрана
setup = XCB.xcb_get_setup(conn)
screen_iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(screen_iter[:data])

puts "✅ Подключен к экрану: #{screen[:width_in_pixels]}x#{screen[:height_in_pixels]}"

# Создание окна
values = FFI::MemoryPointer.new(:uint32, 2)
values[0].write(:uint32, screen[:white_pixel])  # background
values[1].write(:uint32, XCB::XCB_EVENT_MASK_EXPOSURE | XCB::XCB_EVENT_MASK_KEY_PRESS | XCB::XCB_EVENT_MASK_BUTTON_PRESS)

window = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, XCB::XCB_COPY_FROM_PARENT, window, screen[:root],
                      100, 100, 500, 300, 2, XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen[:root_visual], 
                      XCB::XCB_CW_BACK_PIXEL | XCB::XCB_CW_EVENT_MASK, values)

# GC для текста
gc_vals = FFI::MemoryPointer.new(:uint32, 1)
gc_vals.write(:uint32, screen[:black_pixel])
gc = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc, window, XCB::XCB_GC_FOREGROUND, gc_vals)

# Показ окна
XCB.xcb_map_window(conn, window)
XCB.xcb_flush(conn)
puts "✅ Окно показано"

# Цикл событий с тестами захвата
stage = 1
puts "\n🎯 Этап #{stage}: Обычные события (клик в окне или нажмите клавишу)"

loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  
  generic_event = XCB::GenericEvent.new(event)
  type = generic_event[:response_type] & ~0x80
  
  if type == XCB::XCB_EXPOSE
    XCB.xcb_clear_area(conn, 0, window, 0, 0, 500, 300)
    XCB.xcb_flush(conn)
    puts "🖼️ Окно очищено"
    
  elsif type == XCB::XCB_KEY_PRESS
    puts "⌨️ Клавиша нажата (этап #{stage})"
    
    if stage == 1
      # Переходим к захвату указателя
      stage = 2
      puts "\n🎯 Этап #{stage}: Захват указателя..."
      
      grab_cookie = XCB.xcb_grab_pointer(
        conn, 0, window,
        XCB::XCB_EVENT_MASK_BUTTON_PRESS | XCB::XCB_EVENT_MASK_BUTTON_RELEASE,
        XCB::XCB_GRAB_MODE_ASYNC, XCB::XCB_GRAB_MODE_ASYNC,
        XCB::XCB_NONE, XCB::XCB_NONE, XCB::XCB_CURRENT_TIME, XCB::XCB_CURRENT_TIME)
      
      grab_reply = XCB.xcb_grab_pointer_reply(conn, grab_cookie, nil)
      if !grab_reply.null?
        status = grab_reply.read_uint8  # Читаем status из reply
        puts "✅ Указатель захвачен, status: #{status}"
        puts "🖱️ Кликните где угодно на экране - события будут приходить в наше окно"
      else
        puts "❌ Ошибка захвата указателя"
      end
      
    elsif stage == 2
      # Освобождение указателя и захват клавиатуры
      stage = 3
      XCB.xcb_ungrab_pointer(conn)
      puts "✅ Указатель освобожден"
      
      puts "\n🎯 Этап #{stage}: Захват клавиатуры..."
      
      kb_grab_cookie = XCB.xcb_grab_keyboard(
        conn, 0, window, XCB::XCB_CURRENT_TIME,
        XCB::XCB_GRAB_MODE_ASYNC, XCB::XCB_GRAB_MODE_ASYNC, 0)
      
      kb_grab_reply = XCB.xcb_grab_keyboard_reply(conn, kb_grab_cookie, nil)
      if !kb_grab_reply.null?
        status = kb_grab_reply.read_uint8
        puts "✅ Клавиатура захвачена, status: #{status}"
        puts "⌨️ Печатайте - все клавиши будут приходить в наше окно"
      else
        puts "❌ Ошибка захвата клавиатуры"
      end
      
    else
      # Завершение
      XCB.xcb_ungrab_keyboard(conn)
      puts "✅ Клавиатура освобождена"
      break
    end
    
  elsif type == XCB::XCB_BUTTON_PRESS
    puts "🖱️ Кнопка мыши нажата (этап #{stage})"
    
    if stage == 2
      # Проверка позиции указателя во время захвата
      pointer_cookie = XCB.xcb_query_pointer(conn, window)
      pointer_reply = XCB.xcb_query_pointer_reply(conn, pointer_cookie, nil)
      
      if !pointer_reply.null?
        # Читаем координаты из reply структуры
        # win_x и win_y находятся по смещению в структуре
        win_x = pointer_reply.get_int16(8)  # Примерное смещение
        win_y = pointer_reply.get_int16(10)
        root_x = pointer_reply.get_int16(4)
        root_y = pointer_reply.get_int16(6)
        
        puts "📍 Позиция указателя: (#{win_x}, #{win_y}) относительно окна"
        puts "📍 Позиция на экране: (#{root_x}, #{root_y})"
      end
    end
  end
end

# Очистка
XCB.xcb_free_gc(conn, gc)
XCB.xcb_destroy_window(conn, window)
XCB.xcb_disconnect(conn)

puts "✅ Ruby тест захвата ввода завершен"