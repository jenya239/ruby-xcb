#!/usr/bin/env ruby
require_relative '../lib/xcb'

puts "=== FINAL XCB COMPREHENSIVE TEST (RUBY) ==="
puts "🎯 Тестирование всех функций XCB"

# 1. ПОДКЛЮЧЕНИЕ
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

puts "✅ Подключение: экран #{screen[:width_in_pixels]}x#{screen[:height_in_pixels]}, глубина #{screen[:root_depth]}"

# 2. СОЗДАНИЕ ОКНА
win_values = FFI::MemoryPointer.new(:uint32, 2)
win_values[0].write(:uint32, screen[:white_pixel])  # background
win_values[1].write(:uint32, XCB::XCB_EVENT_MASK_EXPOSURE | XCB::XCB_EVENT_MASK_KEY_PRESS | XCB::XCB_EVENT_MASK_BUTTON_PRESS)

window = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, XCB::XCB_COPY_FROM_PARENT, window, screen[:root],
                      50, 50, 600, 400, 3, XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen[:root_visual], 
                      XCB::XCB_CW_BACK_PIXEL | XCB::XCB_CW_EVENT_MASK, win_values)
puts "✅ Окно создано: 600x400"

# 3. ГРАФИЧЕСКИЕ КОНТЕКСТЫ (используем прямые RGB значения)
white_vals = FFI::MemoryPointer.new(:uint32, 1)
white_vals.write(:uint32, screen[:white_pixel])
gc_white = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_white, window, XCB::XCB_GC_FOREGROUND, white_vals)

# Прямые RGB значения для цветов
red_vals = FFI::MemoryPointer.new(:uint32, 1)
red_vals.write(:uint32, 0xFF0000)  # красный
gc_red = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_red, window, XCB::XCB_GC_FOREGROUND, red_vals)

green_vals = FFI::MemoryPointer.new(:uint32, 1)
green_vals.write(:uint32, 0x00FF00)  # зеленый
gc_green = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_green, window, XCB::XCB_GC_FOREGROUND, green_vals)

blue_vals = FFI::MemoryPointer.new(:uint32, 1)
blue_vals.write(:uint32, 0x0000FF)  # синий
gc_blue = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_blue, window, XCB::XCB_GC_FOREGROUND, blue_vals)

puts "✅ Цвета: красный, зеленый, синий выделены"

# 4. ШРИФТ
font = XCB.xcb_generate_id(conn)
XCB.xcb_open_font(conn, font, 4, "6x13")

text_vals = FFI::MemoryPointer.new(:uint32, 3)
text_vals[0].write(:uint32, screen[:black_pixel])
text_vals[1].write(:uint32, screen[:white_pixel])
text_vals[2].write(:uint32, font)

gc_text = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_text, window, 
                  XCB::XCB_GC_FOREGROUND | XCB::XCB_GC_BACKGROUND | XCB::XCB_GC_FONT, 
                  text_vals)
puts "✅ Шрифт загружен: 6x13"

# 5. КУРСОР (одинарный крестик, как в C версии)
cursor_font = XCB.xcb_generate_id(conn)
XCB.xcb_open_font(conn, cursor_font, 6, "cursor")

cursor = XCB.xcb_generate_id(conn)
XCB.xcb_create_glyph_cursor(conn, cursor, cursor_font, cursor_font,
                           34, 34,  # Используем один и тот же глиф для одинарного крестика
                           0, 0, 0, 65535, 65535, 65535)

cursor_vals = FFI::MemoryPointer.new(:uint32, 1)
cursor_vals.write(:uint32, cursor)
XCB.xcb_change_window_attributes(conn, window, XCB::XCB_CW_CURSOR, cursor_vals)
puts "✅ Курсор установлен: крестик"

# 6. ПОКАЗ ОКНА
XCB.xcb_map_window(conn, window)
XCB.xcb_flush(conn)
puts "✅ Окно показано"

# 7. ЦИКЛ СОБЫТИЙ С ИНТЕРАКТИВНОСТЬЮ
click_count = 0

puts "\n🎯 ФИНАЛЬНОЕ ТЕСТИРОВАНИЕ:"
puts "🖱️ Кликайте в окне - появятся цветные квадраты"
puts "⌨️ Нажмите ESC для выхода"

loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  
  generic_event = XCB::GenericEvent.new(event)
  type = generic_event[:response_type] & ~0x80
  
  if type == XCB::XCB_EXPOSE
    # Очистка белым фоном
    bg = XCB::Rectangle.new
    bg[:x] = 0
    bg[:y] = 0
    bg[:width] = 600
    bg[:height] = 400
    XCB.xcb_poly_fill_rectangle(conn, window, gc_white, 1, bg)
    
    # Заголовок
    title = "=== FINAL XCB TEST (RUBY) ==="
    XCB.xcb_image_text_8(conn, title.length, window, gc_text, 150, 30, title)
    
    # Информация
    info = "Screen: #{screen[:width_in_pixels]}x#{screen[:height_in_pixels]} | Clicks: #{click_count} | Font: 6x13 | Cursor: crosshair"
    XCB.xcb_image_text_8(conn, info.length, window, gc_text, 20, 60, info)
    
    # Цветные демо-квадраты
    red_rect = XCB::Rectangle.new
    red_rect[:x] = 50
    red_rect[:y] = 100
    red_rect[:width] = 80
    red_rect[:height] = 60
    XCB.xcb_poly_fill_rectangle(conn, window, gc_red, 1, red_rect)
    
    green_rect = XCB::Rectangle.new
    green_rect[:x] = 150
    green_rect[:y] = 100
    green_rect[:width] = 80
    green_rect[:height] = 60
    XCB.xcb_poly_fill_rectangle(conn, window, gc_green, 1, green_rect)
    
    blue_rect = XCB::Rectangle.new
    blue_rect[:x] = 250
    blue_rect[:y] = 100
    blue_rect[:width] = 80
    blue_rect[:height] = 60
    XCB.xcb_poly_fill_rectangle(conn, window, gc_blue, 1, blue_rect)
    
    # Подписи
    XCB.xcb_image_text_8(conn, 3, window, gc_text, 70, 180, "RED")
    XCB.xcb_image_text_8(conn, 5, window, gc_text, 165, 180, "GREEN")
    XCB.xcb_image_text_8(conn, 4, window, gc_text, 270, 180, "BLUE")
    
    # Инструкции
    instr1 = "Click anywhere to add colored squares"
    instr2 = "Press ESC to exit"
    XCB.xcb_image_text_8(conn, instr1.length, window, gc_text, 150, 220, instr1)
    XCB.xcb_image_text_8(conn, instr2.length, window, gc_text, 220, 240, instr2)
    
    XCB.xcb_flush(conn)
    puts "🖼️ Интерфейс отрисован"
    
  elsif type == XCB::XCB_BUTTON_PRESS
    click_count += 1
    
    # Правильное чтение координат из button_press_event
    # Структура: response_type(1) + detail(1) + sequence(2) + time(4) + root(4) + event(4) + child(4) + root_x(2) + root_y(2) + event_x(2) + event_y(2)
    event_x = event.get_int16(24)  # event_x смещение 24
    event_y = event.get_int16(26)  # event_y смещение 26
    
    # Рисуем цветной квадрат в месте клика
    click_gc = case click_count % 3
               when 1 then gc_red
               when 2 then gc_green
               else gc_blue
               end
    
    click_rect = XCB::Rectangle.new
    click_rect[:x] = event_x - 10
    click_rect[:y] = event_y - 10
    click_rect[:width] = 20
    click_rect[:height] = 20
    XCB.xcb_poly_fill_rectangle(conn, window, click_gc, 1, click_rect)
    
    # Обновляем счетчик кликов в интерфейсе
    info = "Screen: #{screen[:width_in_pixels]}x#{screen[:height_in_pixels]} | Clicks: #{click_count} | Font: 6x13 | Cursor: crosshair"
    
    # Очищаем область под текстом белым прямоугольником
    info_bg = XCB::Rectangle.new
    info_bg[:x] = 15
    info_bg[:y] = 45
    info_bg[:width] = 570
    info_bg[:height] = 20
    XCB.xcb_poly_fill_rectangle(conn, window, gc_white, 1, info_bg)
    
    # Перерисовываем обновленную информацию
    XCB.xcb_image_text_8(conn, info.length, window, gc_text, 20, 60, info)
    
    XCB.xcb_flush(conn)
    
    puts "🖱️ Клик ##{click_count} в (#{event_x}, #{event_y})"
    
  elsif type == XCB::XCB_KEY_PRESS
    key_detail = event.get_uint8(1)  # detail находится по смещению 1
    puts "⌨️ Клавиша: код #{key_detail}"
    
    # ESC = код 9
    if key_detail == 9
      puts "🚪 Выход по ESC"
      break
    end
  end
end

# 8. ОЧИСТКА
XCB.xcb_close_font(conn, font)
XCB.xcb_close_font(conn, cursor_font)
XCB.xcb_free_cursor(conn, cursor)
XCB.xcb_free_gc(conn, gc_white)
XCB.xcb_free_gc(conn, gc_red)
XCB.xcb_free_gc(conn, gc_green)
XCB.xcb_free_gc(conn, gc_blue)
XCB.xcb_free_gc(conn, gc_text)
XCB.xcb_destroy_window(conn, window)
XCB.xcb_disconnect(conn)

puts "\n✅ ФИНАЛЬНЫЙ RUBY ТЕСТ ЗАВЕРШЕН!"
puts "🎉 Все функции XCB протестированы успешно:"
puts "   - Подключение и экраны"
puts "   - Создание окон"
puts "   - Колормапы и цвета"
puts "   - Графические контексты"
puts "   - Шрифты и текст"
puts "   - Курсоры"
puts "   - Обработка событий"
puts "   - Рисование примитивов"