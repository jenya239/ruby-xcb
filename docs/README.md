# Ruby XCB - FFI bindings для libxcb

Ruby FFI привязки к библиотеке `libxcb.so` для работы с X Window System.

## Быстрый старт

```ruby
require_relative 'lib/xcb'

# Подключение к X серверу
conn = XCB.xcb_connect(nil, nil)

# Создание окна
window_id = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, ...)
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)
```

## Структура проекта

```
ruby-xcb/
├── lib/                    # Основные библиотечные файлы
│   ├── xcb.rb             # Главный файл библиотеки
│   └── xcb_complete.rb    # Полные FFI биндинги
├── examples/               # Примеры использования
│   ├── fixed_window.rb    # Рабочий пример окна
│   └── ...
├── test/                   # Тесты
├── docs/                   # Документация
│   ├── README.md          # Подробная документация
│   └── FFI_BINDINGS_GUIDE.md # Руководство по FFI
└── README.md              # Этот файл
```

## Установка

```bash
git clone https://github.com/your-username/ruby-xcb.git
cd ruby-xcb
bundle install
```

## Использование

### Базовый пример

```ruby
require_relative 'lib/xcb'

# Подключение
conn = XCB.xcb_connect(nil, nil)
setup = XCB.xcb_get_setup(conn)
iter = XCB.xcb_setup_roots_iterator(setup)
screen = XCB::Screen.new(iter[:data])

# Создание окна
window_id = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, XCB::XCB_COPY_FROM_PARENT, window_id, 
                     screen[:root], 100, 100, 400, 300, 2,
                     XCB::XCB_WINDOW_CLASS_INPUT_OUTPUT, screen[:root_visual],
                     0, nil)
XCB.xcb_map_window(conn, window_id)
XCB.xcb_flush(conn)
```

## Документация

- [Подробная документация](docs/README.md)
- [Руководство по FFI биндингам](docs/FFI_BINDINGS_GUIDE.md)

## Тестирование

```bash
# Запуск всех тестов
ruby test/test_complete.rb

# Запуск примера окна
DISPLAY=:0 ruby examples/fixed_window.rb
```

## Статистика

- **94 функции** из `libxcb.so`
- **6 структур** данных
- **Полная поддержка** основных операций XCB
- **Совместимость** с MRI Ruby

## Лицензия

MIT License - см. файл [LICENSE](LICENSE).

## Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для новой функции
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

## Проблемы

Если у вас возникли проблемы с FFI биндингами, см. [Руководство по FFI](docs/FFI_BINDINGS_GUIDE.md). 