#!/usr/bin/env ruby
require_relative '../lib/xcb'

puts "=== Ruby XCB Font Test ==="

# Подключение
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "❌ Ошибка подключения к X серверу"
  exit 1
end

# Получение экрана
setup = XCB.xcb_get_setup(conn)
screen_iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(screen_iter[:data])

puts "✅ Подключен к экрану: #{screen[:width_in_pixels]}x#{screen[:height_in_pixels]}"

# Создание окна
values = FFI::MemoryPointer.new(:uint32, 1)
values.write(:uint32, XCB::XCB_EVENT_MASK_EXPOSURE | XCB::XCB_EVENT_MASK_KEY_PRESS)

window = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, XCB::XCB_COPY_FROM_PARENT, window, screen[:root],
                      100, 100, 500, 300, 2, XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen[:root_visual], XCB::XCB_CW_EVENT_MASK, values)

# Загрузка шрифта
font = XCB.xcb_generate_id(conn)
XCB.xcb_open_font(conn, font, 4, "6x13")
XCB.xcb_flush(conn)
puts "✅ Шрифт '6x13' загружен: #{font}"

# Запрос информации о шрифте
font_cookie = XCB.xcb_query_font(conn, font)
font_reply = XCB.xcb_query_font_reply(conn, font_cookie, nil)

if !font_reply.null?
  puts "✅ Информация о шрифте получена"
else
  puts "❌ Ошибка получения информации о шрифте"
end

# GC для белого фона
bg_vals = FFI::MemoryPointer.new(:uint32, 1)
bg_vals.write(:uint32, screen[:white_pixel])
gc_bg = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_bg, window, XCB::XCB_GC_FOREGROUND, bg_vals)

# GC для текста с шрифтом и фоном
text_vals = FFI::MemoryPointer.new(:uint32, 3)
text_vals[0].write(:uint32, screen[:black_pixel])  # foreground
text_vals[1].write(:uint32, screen[:white_pixel])  # background  
text_vals[2].write(:uint32, font)                  # font

gc_text = XCB.xcb_generate_id(conn) 
XCB.xcb_create_gc(conn, gc_text, window, 
                  XCB::XCB_GC_FOREGROUND | XCB::XCB_GC_BACKGROUND | XCB::XCB_GC_FONT, 
                  text_vals)

# Показ окна
XCB.xcb_map_window(conn, window)
XCB.xcb_flush(conn)
puts "✅ Окно показано для вывода текста"

# Цикл событий с рисованием текста
puts "🎯 Нажмите любую клавишу для выхода"

loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  
  generic_event = XCB::GenericEvent.new(event)
  type = generic_event[:response_type] & ~0x80
  
  if type == XCB::XCB_EXPOSE
    # Очистка окна белым фоном
    bg_rect = XCB::Rectangle.new
    bg_rect[:x] = 0
    bg_rect[:y] = 0
    bg_rect[:width] = 500
    bg_rect[:height] = 300
    XCB.xcb_poly_fill_rectangle(conn, window, gc_bg, 1, bg_rect)
    
    # Вывод текста в разных позициях
    text1 = "Hello XCB Fonts!"
    text2 = "Test fonts XCB"
    text3 = "abcdefghijklm"
    text4 = "ABCDEFGHIJKLM"
    text5 = "0123456789"
    
    XCB.xcb_image_text_8(conn, text1.length, window, gc_text, 50, 50, text1)
    XCB.xcb_image_text_8(conn, text2.length, window, gc_text, 50, 80, text2)
    XCB.xcb_image_text_8(conn, text3.length, window, gc_text, 20, 120, text3)
    XCB.xcb_image_text_8(conn, text4.length, window, gc_text, 20, 150, text4)
    XCB.xcb_image_text_8(conn, text5.length, window, gc_text, 20, 180, text5)
    
    # Дополнительная информация
    info = "Font ID: #{font}, Screen: #{screen[:width_in_pixels]}x#{screen[:height_in_pixels]}"
    XCB.xcb_image_text_8(conn, info.length, window, gc_text, 20, 220, info)
    
    XCB.xcb_flush(conn)
    puts "📝 Текст нарисован в окне"
    
  elsif type == XCB::XCB_KEY_PRESS
    break
  end
end

# Очистка
XCB.xcb_close_font(conn, font)
XCB.xcb_free_gc(conn, gc_text)
XCB.xcb_free_gc(conn, gc_bg)
XCB.xcb_destroy_window(conn, window)
XCB.xcb_disconnect(conn)

puts "✅ Тест шрифтов завершен"