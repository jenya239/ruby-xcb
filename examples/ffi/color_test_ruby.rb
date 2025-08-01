#!/usr/bin/env ruby
require_relative '../lib/xcb'

puts "=== Ruby XCB Color Test ==="

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

puts "✅ Подключен к экрану: #{screen[:width_in_pixels]}x#{screen[:height_in_pixels]}, глубина: #{screen[:root_depth]}"

# Создание окна
values = FFI::MemoryPointer.new(:uint32, 1)
values.write(:uint32, XCB::XCB_EVENT_MASK_EXPOSURE | XCB::XCB_EVENT_MASK_KEY_PRESS)

window = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, XCB::XCB_COPY_FROM_PARENT, window, screen[:root],
                      100, 100, 400, 300, 2, XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen[:root_visual], XCB::XCB_CW_EVENT_MASK, values)

# Создание колормапа
colormap = XCB.xcb_generate_id(conn)
XCB.xcb_create_colormap(conn, 0, colormap, window, screen[:root_visual]) # XCB_COLORMAP_ALLOC_NONE = 0
puts "✅ Колормап создан: #{colormap}"

# GC для белого фона (используем готовый белый пиксель экрана)
white_vals = FFI::MemoryPointer.new(:uint32, 1)
white_vals.write(:uint32, screen[:white_pixel])
gc_white = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_white, window, XCB::XCB_GC_FOREGROUND, white_vals)

# GC для красного (используем готовые пиксели экрана вместо alloc_color)
red_vals = FFI::MemoryPointer.new(:uint32, 1)
red_vals.write(:uint32, 0xFF0000) # красный в RGB
gc_red = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_red, window, XCB::XCB_GC_FOREGROUND, red_vals)
puts "✅ Красный GC создан"

# GC для зеленого 
green_vals = FFI::MemoryPointer.new(:uint32, 1)
green_vals.write(:uint32, 0x00FF00) # зеленый в RGB
gc_green = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_green, window, XCB::XCB_GC_FOREGROUND, green_vals)
puts "✅ Зеленый GC создан"

# GC для синего
blue_vals = FFI::MemoryPointer.new(:uint32, 1)
blue_vals.write(:uint32, 0x0000FF) # синий в RGB
gc_blue = XCB.xcb_generate_id(conn)
XCB.xcb_create_gc(conn, gc_blue, window, XCB::XCB_GC_FOREGROUND, blue_vals)
puts "✅ Синий GC создан"

# Показ окна
XCB.xcb_map_window(conn, window)
XCB.xcb_flush(conn)
puts "✅ Окно показано с цветными прямоугольниками"

# Цикл событий с рисованием
puts "🎯 Нажмите любую клавишу для выхода"

loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  
  generic_event = XCB::GenericEvent.new(event)
  type = generic_event[:response_type] & ~0x80
  
  if type == XCB::XCB_EXPOSE
    # Очистка окна белым фоном
    white_bg = XCB::Rectangle.new
    white_bg[:x] = 0
    white_bg[:y] = 0
    white_bg[:width] = 400
    white_bg[:height] = 300
    XCB.xcb_poly_fill_rectangle(conn, window, gc_white, 1, white_bg)
    
    # Рисование цветных прямоугольников
    red_rect = XCB::Rectangle.new
    red_rect[:x] = 50
    red_rect[:y] = 50
    red_rect[:width] = 100
    red_rect[:height] = 80
    XCB.xcb_poly_fill_rectangle(conn, window, gc_red, 1, red_rect)
    
    green_rect = XCB::Rectangle.new
    green_rect[:x] = 200
    green_rect[:y] = 50
    green_rect[:width] = 100
    green_rect[:height] = 80
    XCB.xcb_poly_fill_rectangle(conn, window, gc_green, 1, green_rect)
    
    blue_rect = XCB::Rectangle.new
    blue_rect[:x] = 125
    blue_rect[:y] = 150
    blue_rect[:width] = 100
    blue_rect[:height] = 80
    XCB.xcb_poly_fill_rectangle(conn, window, gc_blue, 1, blue_rect)
    
    XCB.xcb_flush(conn)
    puts "🎨 Окно очищено и цветные прямоугольники нарисованы"
    
  elsif type == XCB::XCB_KEY_PRESS
    break
  end
end

# Очистка
XCB.xcb_free_gc(conn, gc_white)
XCB.xcb_free_gc(conn, gc_red)
XCB.xcb_free_gc(conn, gc_green)
XCB.xcb_free_gc(conn, gc_blue)
XCB.xcb_free_colormap(conn, colormap)
XCB.xcb_destroy_window(conn, window)
XCB.xcb_disconnect(conn)

puts "✅ Тест цветов завершен"