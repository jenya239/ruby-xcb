# Ruby XCB Bindings

Полные Ruby FFI привязки к библиотеке libxcb для работы с X Window System.

## Установка

```bash
bundle install
```

## Быстрый старт

```bash
ruby xcb.rb
```

## Структура проекта

```
ruby-xcb/
├── lib/           # Основная библиотека
│   ├── xcb.rb     # Главный файл библиотеки
│   └── xcb_complete.rb  # Полные привязки (94 функции)
├── test/          # Тесты
│   ├── simple_test.rb
│   ├── window_test.rb
│   ├── final_test.rb
│   └── test_complete.rb
├── examples/      # Примеры использования
│   └── example.rb
├── docs/          # Документация
│   └── README.md
├── Gemfile        # Зависимости
└── xcb.rb         # Основной файл проекта
```

## Использование

```ruby
require_relative 'lib/xcb'

# Подключение к X серверу
screen_ptr = FFI::MemoryPointer.new(:int)
conn = XCB.xcb_connect(nil, screen_ptr)

# Создание окна
window_id = XCB.xcb_generate_id(conn)
cookie = XCB.xcb_create_window(
  conn, 0, window_id, 1, 100, 100, 400, 300, 0, 1, 0, 0, nil
)

# Показ окна
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)
```

## Тесты

```bash
# Простой тест подключения
ruby test/simple_test.rb

# Тест создания окна
ruby test/window_test.rb

# Комплексный тест функций
ruby test/final_test.rb
```

## Примеры

```bash
# Пример создания окна
ruby examples/example.rb
```

## Документация

Подробная документация находится в `docs/README.md`.

## Статистика

- **94 функции** привязаны к libxcb
- **5 структур** FFI определены
- **10 констант** XCB
- **40 типов** указателей
- **15+ функций** протестированы и работают

Полная совместимость с MRI Ruby и минималистичный дизайн. 