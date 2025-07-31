#!/usr/bin/env ruby

require_relative '../lib/xcb'

# Пример использования XCB привязок
class XCBExample
  def initialize
    @conn = nil
    @screen = nil
    @window = nil
  end
  
  def connect(display_name = nil)
    # Подключаемся к X серверу
    screen_ptr = FFI::MemoryPointer.new(:int)
    @conn = XCB.xcb_connect(display_name, screen_ptr)
    
    if @conn.null?
      puts "Ошибка подключения к X серверу"
      return false
    end
    
    if XCB.xcb_connection_has_error(@conn) != 0
      puts "Ошибка соединения с X сервером"
      return false
    end
    
    @screen = screen_ptr.read_int
    puts "Подключено к экрану: #{@screen}"
    true
  end
  
  def disconnect
    return unless @conn
    XCB.xcb_disconnect(@conn)
    @conn = nil
  end
  
  def create_simple_window
    return unless @conn
    
    # Получаем setup информацию
    setup = XCB.xcb_get_setup(@conn)
    return unless setup
    
    # Создаем окно
    @window = XCB.xcb_generate_id(@conn)
    
    # Создаем окно (упрощенная версия)
    cookie = XCB.xcb_create_window(
      @conn,                    # соединение
      0,                        # глубина (CopyFromParent)
      @window,                  # window id
      1,                        # parent window (root)
      100, 100,                 # x, y
      400, 300,                 # width, height
      0,                        # border width
      1,                        # class (InputOutput)
      0,                        # visual (CopyFromParent)
      0,                        # value mask
      nil                       # value list
    )
    
    # Проверяем ошибки
    error = XCB.xcb_request_check(@conn, cookie)
    if error
      puts "Ошибка создания окна"
      return false
    end
    
    # Показываем окно
    XCB.xcb_map_window(@conn, @window)
    XCB.xcb_flush(@conn)
    
    puts "Окно создано с ID: #{@window}"
    true
  end
  
  def wait_for_events
    return unless @conn
    
    puts "Ожидание событий (Ctrl+C для выхода)..."
    
    loop do
      event = XCB.xcb_wait_for_event(@conn)
      next if event.null?
      
      event_struct = XCB::GenericEvent.new(event)
      event_type = event_struct[:response_type]
      
      case event_type
      when 2  # KeyPress
        puts "Нажата клавиша"
      when 3  # KeyRelease  
        puts "Отпущена клавиша"
      when 4  # ButtonPress
        puts "Нажата кнопка мыши"
      when 5  # ButtonRelease
        puts "Отпущена кнопка мыши"
      when 6  # MotionNotify
        puts "Движение мыши"
      when 12 # Expose
        puts "Окно перерисовано"
      when 33 # ClientMessage
        puts "Сообщение клиента"
        break
      else
        puts "Неизвестное событие: #{event_type}"
      end
    end
  rescue Interrupt
    puts "\nВыход..."
  end
  
  def run
    return unless connect
    return unless create_simple_window
    
    wait_for_events
  ensure
    disconnect
  end
end

# Запуск примера
if __FILE__ == $0
  example = XCBExample.new
  example.run
end 