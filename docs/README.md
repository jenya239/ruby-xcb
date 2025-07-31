# Ruby XCB Bindings - Подробная документация

Полные Ruby FFI привязки к библиотеке libxcb для работы с X Window System.

## Установка

```bash
bundle install
```

## Использование

```ruby
require_relative 'lib/xcb'

# Подключение к X серверу
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

if conn.null?
  puts "Ошибка подключения"
  exit 1
end

# Создание окна
window_id = XCB.xcb_generate_id(conn)
cookie = XCB.xcb_create_window(
  conn, 0, window_id, 1,    # соединение, глубина, id, родитель
  100, 100, 400, 300,       # x, y, width, height
  0, 1, 0, 0, nil          # border, class, visual, mask, values
)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)

# Ожидание событий
loop do
  event = XCB.xcb_wait_for_event(conn)
  break if event.null?
  # Обработка события...
end

# Отключение
XCB.xcb_disconnect(conn)
```

## Основные функции

### Подключение
- `xcb_connect(display, screen_ptr)` - подключение к X серверу
- `xcb_disconnect(conn)` - отключение
- `xcb_connection_has_error(conn)` - проверка ошибок

### Окна
- `xcb_create_window(...)` - создание окна
- `xcb_destroy_window(conn, window)` - уничтожение окна
- `xcb_map_window(conn, window)` - показ окна
- `xcb_unmap_window(conn, window)` - скрытие окна

### События
- `xcb_wait_for_event(conn)` - ожидание события
- `xcb_poll_for_event(conn)` - проверка событий без ожидания

### Рисование
- `xcb_clear_area(...)` - очистка области
- `xcb_copy_area(...)` - копирование области
- `xcb_poly_point(...)` - рисование точек
- `xcb_poly_line(...)` - рисование линий

### Графический контекст
- `xcb_create_gc(...)` - создание GC
- `xcb_free_gc(conn, gc)` - освобождение GC
- `xcb_change_gc(...)` - изменение GC

### Свойства
- `xcb_intern_atom(...)` - интернирование атома
- `xcb_change_property(...)` - изменение свойства
- `xcb_get_property(...)` - получение свойства

### Ввод
- `xcb_grab_pointer(...)` - захват указателя
- `xcb_grab_keyboard(...)` - захват клавиатуры
- `xcb_query_pointer(...)` - запрос позиции указателя

### Расширения
- `xcb_query_extension(...)` - запрос расширения
- `xcb_list_extensions(...)` - список расширений

## Структуры

- `XCB::GenericEvent` - общая структура события
- `XCB::GenericError` - структура ошибки
- `XCB::VoidCookie` - cookie для запросов
- `XCB::AuthInfo` - информация аутентификации

## Константы

- `XCB::X_PROTOCOL` - версия протокола (11)
- `XCB::XCB_CONN_ERROR` - код ошибки соединения
- `XCB::X_TCP_PORT` - TCP порт X сервера (6000)

## Примеры

### Базовый тест
```bash
ruby test/simple_test.rb
```

### Создание окна
```bash
ruby test/window_test.rb
```

### Комплексный тест
```bash
ruby test/final_test.rb
```

### Пример использования
```bash
ruby examples/example.rb
```

## Требования

- Ruby с поддержкой FFI
- libxcb-dev (Ubuntu/Debian)
- X11 development headers

## Статистика

- **94 функции** привязаны к libxcb
- **5 структур** FFI определены
- **10 констант** XCB
- **40 типов** указателей
- **15+ функций** протестированы и работают

### Протестированные функции:
- ✅ Подключение к X серверу
- ✅ Создание и управление окнами
- ✅ Графические контексты
- ✅ Пиксмапы
- ✅ Рисование (очистка, копирование)
- ✅ Свойства и атомы
- ✅ События
- ✅ Расширения
- ✅ Утилиты

Полная совместимость с MRI Ruby и минималистичный дизайн. 