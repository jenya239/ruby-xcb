# Руководство по созданию Ruby FFI биндингов

## Обзор

Это руководство описывает лучшие практики создания Ruby FFI биндингов для C библиотек, основанные на опыте создания биндингов для `libxcb.so`.

## Основные принципы

### 1. Изучение C API

**Всегда начинайте с изучения оригинальных заголовочных файлов:**

```c
#include <xcb/xcb.h>
#include <xcb/xcb_util.h>

// Понимайте типы возвращаемых значений
xcb_screen_iterator_t xcb_setup_roots_iterator(xcb_setup_t *R); // структура по значению
xcb_screen_t *xcb_setup_roots_next(xcb_screen_iterator_t *i);  // указатель
```

**Создайте простой C пример для тестирования:**
```c
#include <xcb/xcb.h>
int main() {
    xcb_connection_t *conn = xcb_connect(NULL, NULL);
    // Ваш код
    return 0;
}
```

### 2. Правильное определение FFI структур

**Для структур, возвращаемых по значению:**
```ruby
attach_function :func, [:pointer], MyStruct.by_value
```

**Для структур, возвращаемых по указателю:**
```ruby
attach_function :func, [:pointer], :pointer
```

**Проверяйте размеры и выравнивание:**
```ruby
class MyStruct < FFI::Struct
  layout :field1, :uint32,    # 4 байта
         :field2, :uint16,     # 2 байта + 2 байта padding
         :field3, :uint32      # 4 байта
end
```

### 3. Использование правильных констант

**Не хардкодите значения:**
```ruby
# Правильно
XCB_COPY_FROM_PARENT = 0
XCB_WINDOW_CLASS_INPUT_OUTPUT = 1
XCB_CW_BACK_PIXEL = 0x00000002

# Неправильно
root_window = 1  # Хардкод
```

### 4. Проверка возвращаемых значений

```ruby
# Всегда проверяйте ошибки
if conn.null? || XCB.xcb_connection_has_error(conn) != 0
  puts "Ошибка подключения"
  exit 1
end

# Проверяйте структуры
puts "Root: #{screen[:root]}"
puts "Visual: #{screen[:root_visual]}"
```

## Типичные проблемы и решения

### Проблема: Окно создается, но не отображается

**Причины:**
- Неправильный root window
- Отсутствие атрибутов окна
- Неправильный visual

**Решение:**
```ruby
# Получайте screen правильно
setup = XCB.xcb_get_setup(conn)
iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(iter[:data])

root = screen[:root]
visual = screen[:root_visual]

# Добавляйте атрибуты окна
value_mask = XCB::XCB_CW_BACK_PIXEL | XCB::XCB_CW_EVENT_MASK
value_list = FFI::MemoryPointer.new(:uint32, 2)
value_list.write_array_of_uint32([white_pixel, XCB::XCB_EVENT_MASK_EXPOSURE])
```

### Проблема: Segmentation fault

**Причины:**
- Неправильные типы данных в структурах
- Неправильные указатели
- Неправильные размеры структур

**Решение:**
```ruby
# Проверяйте структуры
class Screen < FFI::Struct
  layout :root, :uint32,             # Root window
         :default_colormap, :uint32, # Default colormap
         :white_pixel, :uint32,      # White pixel value
         # ... остальные поля
end
```

### Проблема: Функции не работают

**Причины:**
- Неправильные сигнатуры функций
- Неправильные типы параметров
- Отсутствие необходимых структур

**Решение:**
```ruby
# Создавайте вспомогательные функции
def get_screen_info(conn)
  setup = XCB.xcb_get_setup(conn)
  iter = XCB.xcb_setup_roots_iterator(setup)
  screen = XCB::Screen.new(iter[:data])
  return screen
end
```

## Процесс отладки

### 1. Создайте рабочий C пример
```c
#include <xcb/xcb.h>
int main() {
    xcb_connection_t *conn = xcb_connect(NULL, NULL);
    xcb_screen_t *screen = xcb_setup_roots_iterator(xcb_get_setup(conn)).data;
    // Ваш код
    return 0;
}
```

### 2. Сравните с Ruby версией
```ruby
conn = XCB.xcb_connect(nil, screen_ptr)
setup = XCB.xcb_get_setup(conn)
iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(iter[:data])
```

### 3. Проверяйте каждый шаг
```ruby
puts "Connection: #{conn.null? ? 'NULL' : 'OK'}"
puts "Setup: #{setup.null? ? 'NULL' : 'OK'}"
puts "Root: #{screen[:root]}"
```

### 4. Используйте отладку
```ruby
# Проверяйте структуры
puts "Screen size: #{XCB::Screen.size}"
puts "Iterator size: #{XCB::ScreenIterator.size}"
```

## Лучшие практики

### 1. Документируйте сложные случаи
```ruby
# xcb_setup_roots_iterator возвращает структуру по значению
# поэтому используем .by_value
attach_function :xcb_setup_roots_iterator, [:pointer], ScreenIterator.by_value
```

### 2. Создавайте тестовые примеры
```ruby
# Простой тест для проверки биндингов
def test_basic_functions
  conn = XCB.xcb_connect(nil, nil)
  assert !conn.null?
  # ... остальные тесты
end
```

### 3. Используйте правильные типы данных
```ruby
# Для указателей
:pointer

# Для структур
MyStruct.by_value

# Для примитивов
:uint32, :int16, :uint8
```

### 4. Проверяйте жизненный цикл объектов
```ruby
# Всегда освобождайте ресурсы
XCB.xcb_disconnect(conn)
```

## Частые ошибки

1. **Хардкод значений вместо констант**
2. **Неправильные типы возвращаемых значений**
3. **Отсутствие проверки ошибок**
4. **Неправильные размеры структур**
5. **Игнорирование атрибутов объектов**

## Заключение

Создание FFI биндингов требует глубокого понимания C API. Всегда:
- Изучайте оригинальную документацию
- Создавайте рабочие C примеры
- Проверяйте каждый шаг
- Документируйте сложные случаи
- Тестируйте на реальных примерах 