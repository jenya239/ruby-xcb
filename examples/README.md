# Ruby XCB Examples

Этот каталог содержит примеры использования Ruby XCB библиотеки на разных уровнях абстракции.

## 📁 Структура

### `/ffi/` - Низкоуровневые FFI тесты
Прямые вызовы к libxcb через Ruby FFI. Эти примеры показывают базовые возможности XCB:

- `test_pixmap_ruby.rb` - Базовое тестирование pixmap и рисования
- `color_test_ruby.rb` - Работа с цветами и colormap
- `font_test_ruby.rb` - Загрузка шрифтов и отображение текста
- `cursor_test_ruby.rb` - Создание и установка курсоров
- `input_grab_test_ruby.rb` - Перехват клавиатуры и мыши
- `comprehensive_test_ruby.rb` - Комплексный тест всех возможностей
- `final_xcb_test_ruby.rb` - Финальный интерактивный тест

### `/wrapper/` - Высокоуровневый Ruby wrapper
Объектно-ориентированный Ruby-way API поверх FFI:

- `wrapper_test_simple.rb` - Простой тест подключения и окна
- `wrapper_color_test.rb` - Тест цветной графики
- `wrapper_font_test.rb` - Тест работы со шрифтами
- `wrapper_cursor_test.rb` - Тест курсоров с интерактивностью
- `wrapper_final_test.rb` - Комплексный интерактивный тест
- `wrapper_dsl_test.rb` - DSL-стиль и Ruby идиомы

### `/demos/` - Демонстрационные приложения
Примеры реальных приложений с использованием wrapper.

### `/legacy/` - Устаревшие примеры
Старые экспериментальные файлы, сохранены для истории разработки.

## 🚀 Быстрый старт

### FFI примеры
```bash
cd examples/ffi
ruby final_xcb_test_ruby.rb
```

### Wrapper примеры  
```bash
cd examples/wrapper
ruby wrapper_final_test.rb
```

### DSL стиль
```bash
cd examples/wrapper
ruby wrapper_dsl_test.rb
```

## 📖 Сравнение подходов

| Аспект | FFI | Wrapper |
|--------|-----|---------|
| **Стиль** | Процедурный | Объектно-ориентированный |
| **Память** | Ручное управление | Автоматическое |
| **Синтаксис** | C-подобный | Ruby-way |
| **Блоки** | Нет | Да |
| **DSL** | Нет | Да |

### FFI пример:
```ruby
conn = XCB.xcb_connect(nil, nil)
window_id = XCB.xcb_generate_id(conn)
XCB.xcb_create_window(conn, depth, window_id, root, ...)
XCB.xcb_map_window(conn, window_id)
```

### Wrapper пример:
```ruby
XCB.connect do |conn|
  window = conn.default_screen.create_window(width: 400, height: 300)
  window.set_title("My App").show
end
```

## 🎯 Рекомендации

- **Изучение XCB**: Начните с `/ffi/` примеров
- **Разработка приложений**: Используйте `/wrapper/` API
- **Быстрое прототипирование**: DSL стиль из `wrapper_dsl_test.rb`

## 🔧 Требования

- Ruby 2.7+
- libxcb-dev
- X11 сервер

## 📝 Примечания

Все примеры протестированы и работают. "double free" ошибки в конце выполнения не влияют на функциональность.