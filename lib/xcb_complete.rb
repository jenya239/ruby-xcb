require 'ffi'

module XCB
  extend FFI::Library
  
  # Загружаем библиотеку libxcb
  ffi_lib 'xcb'
  
  # Основные структуры XCB
  class Connection < FFI::Struct
    # xcb_connection_t - непрозрачная структура соединения
  end
  
  class GenericEvent < FFI::Struct
    layout :response_type, :uint8,    # Тип события
           :pad0, :uint8,             # Заполнение
           :sequence, :uint16,         # Номер последовательности
           :length, :uint32            # Длина события
  end
  
  class GenericReply < FFI::Struct
    layout :response_type, :uint8,    # Тип ответа
           :pad0, :uint8,             # Заполнение
           :sequence, :uint16,         # Номер последовательности
           :length, :uint32            # Длина ответа
  end
  
  class GenericError < FFI::Struct
    layout :response_type, :uint8,    # Тип ответа
           :error_code, :uint8,       # Код ошибки
           :sequence, :uint16,         # Номер последовательности
           :resource_id, :uint32,      # ID ресурса
           :minor_code, :uint16,       # Младший код
           :major_code, :uint8,        # Старший код
           :pad0, :uint8,              # Заполнение
           :pad, [:uint32, 5]          # Дополнительное заполнение
  end
  
  class VoidCookie < FFI::Struct
    layout :sequence, :uint32          # Номер последовательности
  end
  
  class AuthInfo < FFI::Struct
    layout :namelen, :int,             # Длина имени
           :name, :pointer,            # Указатель на имя
           :datalen, :int,             # Длина данных
           :data, :pointer             # Указатель на данные
  end
  
  # Структура для screen
  class Screen < FFI::Struct
    layout :root, :uint32,             # Root window
           :default_colormap, :uint32, # Default colormap
           :white_pixel, :uint32,      # White pixel value
           :black_pixel, :uint32,      # Black pixel value
           :current_input_masks, :uint32, # Current input masks
           :width_in_pixels, :uint16,  # Width in pixels
           :height_in_pixels, :uint16, # Height in pixels
           :width_in_millimeters, :uint16, # Width in millimeters
           :height_in_millimeters, :uint16, # Height in millimeters
           :min_installed_maps, :uint16, # Min installed maps
           :max_installed_maps, :uint16, # Max installed maps
           :root_visual, :uint32,      # Root visual
           :backing_stores, :uint8,    # Backing stores
           :save_unders, :uint8,       # Save unders
           :root_depth, :uint8,        # Root depth
           :allowed_depths_len, :uint8 # Allowed depths length
  end
  
  # Структура для screen iterator
  class ScreenIterator < FFI::Struct
    layout :data, :pointer,            # Pointer to screen data
           :rem, :int,                 # Remaining screens
           :index, :int                # Current index
  end
  
  # Структура для прямоугольника
  class Rectangle < FFI::Struct
    layout :x, :int16,                 # X координата
           :y, :int16,                 # Y координата
           :width, :uint16,            # Ширина
           :height, :uint16            # Высота
  end
  
  # Структура для точки
  class Point < FFI::Struct
    layout :x, :int16,                 # X координата
           :y, :int16                  # Y координата
  end
  
  # Константы XCB
  X_PROTOCOL = 11                      # Версия протокола X
  X_PROTOCOL_REVISION = 0              # Ревизия протокола
  X_TCP_PORT = 6000                    # TCP порт X сервера
  XCB_CONN_ERROR = 1                   # Ошибка соединения
  XCB_CONN_CLOSED_EXT_NOTSUPPORTED = 2 # Расширение не поддерживается
  XCB_CONN_CLOSED_MEM_INSUFFICIENT = 3 # Недостаточно памяти
  XCB_CONN_CLOSED_REQ_LEN_EXCEED = 4   # Превышена длина запроса
  XCB_CONN_CLOSED_PARSE_ERR = 5        # Ошибка парсинга
  XCB_CONN_CLOSED_INVALID_SCREEN = 6   # Неверный экран
  XCB_CONN_CLOSED_FDPASSING_FAILED = 7 # Ошибка передачи файлового дескриптора
  
  # Константы для создания окна
  XCB_COPY_FROM_PARENT = 0             # Copy depth from parent
  XCB_WINDOW_CLASS_INPUT_OUTPUT = 1    # InputOutput window class
  XCB_WINDOW_CLASS_INPUT_ONLY = 2      # InputOnly window class
  
  # Константы для атрибутов окна
  XCB_CW_BACK_PIXEL = 0x00000002      # Background pixel
  XCB_CW_BORDER_PIXEL = 0x00000004    # Border pixel
  XCB_CW_EVENT_MASK = 0x00000800      # Event mask
  XCB_CW_CURSOR = 0x00004000          # Cursor
  
  # Константы событий
  XCB_EVENT_MASK_EXPOSURE = 0x00008000 # Exposure events
  XCB_EVENT_MASK_KEY_PRESS = 0x00000001 # Key press events
  XCB_EVENT_MASK_BUTTON_PRESS = 0x00000004 # Button press events
  XCB_EVENT_MASK_BUTTON_RELEASE = 0x00000008 # Button release events
  XCB_EVENT_MASK_POINTER_MOTION = 0x00000040 # Pointer motion events
  XCB_EVENT_MASK_STRUCTURE_NOTIFY = 0x00002000 # Structure notify events
  
  # Константы типов событий
  XCB_EXPOSE = 12                      # Expose event
  XCB_KEY_PRESS = 2                    # Key press event
  XCB_BUTTON_PRESS = 4                 # Button press event
  
  # Константы для линий
  XCB_COORD_MODE_ORIGIN = 0            # Coordinate mode
  
  # Константы для захвата
  XCB_GRAB_MODE_SYNC = 0               # Synchronous grab
  XCB_GRAB_MODE_ASYNC = 1              # Asynchronous grab
  XCB_NONE = 0                         # None value
  XCB_CURRENT_TIME = 0                 # Current time
  
  # Константы для графического контекста
  XCB_GC_FOREGROUND = 0x00000004      # Foreground pixel
  XCB_GC_BACKGROUND = 0x00000008      # Background pixel
  XCB_GC_LINE_WIDTH = 0x00000010      # Line width
  XCB_GC_FONT = 0x00004000            # Font
  
  # === ФУНКЦИИ ПОДКЛЮЧЕНИЯ ===
  
  # Подключение к X серверу по имени дисплея
  attach_function :xcb_connect, [:string, :pointer], :pointer
  # Отключение от X сервера
  attach_function :xcb_disconnect, [:pointer], :void
  # Проверка ошибок соединения
  attach_function :xcb_connection_has_error, [:pointer], :int
  # Получение файлового дескриптора соединения
  attach_function :xcb_get_file_descriptor, [:pointer], :int
  # Получение setup информации от сервера
  attach_function :xcb_get_setup, [:pointer], :pointer
  # Получение итератора экранов
  attach_function :xcb_setup_roots_iterator, [:pointer], ScreenIterator.by_value
  # Генерация уникального ID ресурса
  attach_function :xcb_generate_id, [:pointer], :uint32
  
  # === ФУНКЦИИ СОБЫТИЙ ===
  
  # Ожидание события
  attach_function :xcb_wait_for_event, [:pointer], :pointer
  # Проверка событий без ожидания
  attach_function :xcb_poll_for_event, [:pointer], :pointer
  # Проверка событий в очереди
  attach_function :xcb_poll_for_queued_event, [:pointer], :pointer
  # Ожидание ответа на запрос
  attach_function :xcb_wait_for_reply, [:pointer, :uint32, :pointer], :pointer
  # Проверка ответа без ожидания
  attach_function :xcb_poll_for_reply, [:pointer, :uint32, :pointer, :pointer], :int
  # Проверка ошибок запроса
  attach_function :xcb_request_check, [:pointer, VoidCookie], :pointer
  
  # === ФУНКЦИИ ОТПРАВКИ ЗАПРОСОВ ===
  
  # Отправка буферизованных запросов
  attach_function :xcb_flush, [:pointer], :int
  # Отправка запроса
  attach_function :xcb_send_request, [:pointer, :int, :pointer, :pointer], :uint32
  # Отбрасывание ответа
  attach_function :xcb_discard_reply, [:pointer, :uint32], :void
  
  # === ФУНКЦИИ ОКОН ===
  
  # Создание окна
  attach_function :xcb_create_window, [:pointer, :uint8, :uint32, :uint32, :int16, :int16, :uint16, :uint16, :uint16, :uint16, :uint32, :uint32, :pointer], VoidCookie
  # Уничтожение окна
  attach_function :xcb_destroy_window, [:pointer, :uint32], VoidCookie
  # Показ окна
  attach_function :xcb_map_window, [:pointer, :uint32], VoidCookie
  # Скрытие окна
  attach_function :xcb_unmap_window, [:pointer, :uint32], VoidCookie
  # Настройка окна
  attach_function :xcb_configure_window, [:pointer, :uint32, :uint16, :pointer], VoidCookie
  # Изменение атрибутов окна
  attach_function :xcb_change_window_attributes, [:pointer, :uint32, :uint32, :pointer], VoidCookie
  # Получение геометрии окна
  attach_function :xcb_get_geometry, [:pointer, :uint32], VoidCookie
  # Получение ответа геометрии
  attach_function :xcb_get_geometry_reply, [:pointer, :uint32, :pointer], :pointer
  
  # === ФУНКЦИИ СВОЙСТВ ===
  
  # Интернирование атома
  attach_function :xcb_intern_atom, [:pointer, :uint8, :uint16, :string], VoidCookie
  # Получение ответа интернирования атома
  attach_function :xcb_intern_atom_reply, [:pointer, :uint32, :pointer], :pointer
  # Изменение свойства окна
  attach_function :xcb_change_property, [:pointer, :uint8, :uint32, :uint32, :uint32, :uint8, :uint32, :pointer], VoidCookie
  # Получение свойства окна
  attach_function :xcb_get_property, [:pointer, :uint8, :uint32, :uint32, :uint32, :uint32, :uint32], :uint32
  # Получение ответа свойства
  attach_function :xcb_get_property_reply, [:pointer, :uint32, :pointer], :pointer
  
  # === ФУНКЦИИ ГРАФИЧЕСКОГО КОНТЕКСТА ===
  
  # Создание графического контекста
  attach_function :xcb_create_gc, [:pointer, :uint32, :uint32, :uint32, :pointer], VoidCookie
  # Освобождение графического контекста
  attach_function :xcb_free_gc, [:pointer, :uint32], VoidCookie
  # Изменение графического контекста
  attach_function :xcb_change_gc, [:pointer, :uint32, :uint32, :pointer], VoidCookie
  
  # === ФУНКЦИИ РИСОВАНИЯ ===
  
  # Очистка области
  attach_function :xcb_clear_area, [:pointer, :uint8, :uint32, :int16, :int16, :uint16, :uint16], VoidCookie
  # Копирование области
  attach_function :xcb_copy_area, [:pointer, :uint32, :uint32, :uint32, :int16, :int16, :int16, :int16, :uint16, :uint16], VoidCookie
  # Рисование точек
  attach_function :xcb_poly_point, [:pointer, :uint8, :uint32, :uint32, :uint32, :pointer], VoidCookie
  # Рисование линий
  attach_function :xcb_poly_line, [:pointer, :uint8, :uint32, :uint32, :uint32, :pointer], VoidCookie
  # Рисование прямоугольников
  attach_function :xcb_poly_rectangle, [:pointer, :uint32, :uint32, :uint32, :pointer], VoidCookie
  # Заливка прямоугольников
  attach_function :xcb_poly_fill_rectangle, [:pointer, :uint32, :uint32, :uint32, :pointer], VoidCookie
  # Вывод текста
  attach_function :xcb_image_text_8, [:pointer, :uint8, :uint32, :uint32, :int16, :int16, :string], VoidCookie
  
  # === ФУНКЦИИ ПИКСМАПОВ ===
  
  # Создание пиксмапа
  attach_function :xcb_create_pixmap, [:pointer, :uint8, :uint32, :uint32, :uint16, :uint16], VoidCookie
  # Освобождение пиксмапа
  attach_function :xcb_free_pixmap, [:pointer, :uint32], VoidCookie
  
  # === ФУНКЦИИ ШРИФТОВ ===
  
  # Открытие шрифта
  attach_function :xcb_open_font, [:pointer, :uint32, :uint16, :string], VoidCookie
  # Закрытие шрифта
  attach_function :xcb_close_font, [:pointer, :uint32], VoidCookie
  # Запрос информации о шрифте
  attach_function :xcb_query_font, [:pointer, :uint32], :uint32
  # Получение ответа о шрифте
  attach_function :xcb_query_font_reply, [:pointer, :uint32, :pointer], :pointer
  
  # === ФУНКЦИИ КУРСОРА ===
  
  # Создание курсора
  attach_function :xcb_create_cursor, [:pointer, :uint32, :uint32, :uint32, :uint32, :uint16, :uint16, :uint16, :uint16, :uint16, :uint16], VoidCookie
  # Создание курсора из глифа
  attach_function :xcb_create_glyph_cursor, [:pointer, :uint32, :uint32, :uint32, :uint32, :uint32, :uint16, :uint16, :uint16, :uint16, :uint16, :uint16], VoidCookie
  # Освобождение курсора
  attach_function :xcb_free_cursor, [:pointer, :uint32], VoidCookie
  
  # === ФУНКЦИИ КОЛОРМАПА ===
  
  # Создание колормапа
  attach_function :xcb_create_colormap, [:pointer, :uint8, :uint32, :uint32, :uint32], VoidCookie
  # Освобождение колормапа
  attach_function :xcb_free_colormap, [:pointer, :uint32], VoidCookie
  # Выделение цвета
  attach_function :xcb_alloc_color, [:pointer, :uint32, :uint16, :uint16, :uint16], :uint32
  # Получение ответа выделения цвета
  attach_function :xcb_alloc_color_reply, [:pointer, :uint32, :pointer], :pointer
  
  # === ФУНКЦИИ ВВОДА ===
  
  # Захват указателя
  attach_function :xcb_grab_pointer, [:pointer, :uint8, :uint32, :uint32, :uint16, :uint16, :uint32, :uint32, :uint32, :uint32], :uint32
  # Получение ответа захвата указателя
  attach_function :xcb_grab_pointer_reply, [:pointer, :uint32, :pointer], :pointer
  # Освобождение указателя
  attach_function :xcb_ungrab_pointer, [:pointer], VoidCookie
  # Запрос позиции указателя
  attach_function :xcb_query_pointer, [:pointer, :uint32], :uint32
  # Получение ответа позиции указателя
  attach_function :xcb_query_pointer_reply, [:pointer, :uint32, :pointer], :pointer
  
  # === ФУНКЦИИ КЛАВИАТУРЫ ===
  
  # Захват клавиатуры
  attach_function :xcb_grab_keyboard, [:pointer, :uint8, :uint32, :uint32, :uint16, :uint16, :uint32], :uint32
  # Получение ответа захвата клавиатуры
  attach_function :xcb_grab_keyboard_reply, [:pointer, :uint32, :pointer], :pointer
  # Освобождение клавиатуры
  attach_function :xcb_ungrab_keyboard, [:pointer], VoidCookie
  # Захват клавиши
  attach_function :xcb_grab_key, [:pointer, :uint8, :uint32, :uint32, :uint16, :uint16, :uint32, :uint32], VoidCookie
  # Освобождение клавиши
  attach_function :xcb_ungrab_key, [:pointer, :uint32, :uint32, :uint16, :uint16], VoidCookie
  
  # === ФУНКЦИИ ЭКРАНА ===
  
  # Получение заставки экрана
  attach_function :xcb_get_screen_saver, [:pointer], :uint32
  # Получение ответа заставки экрана
  attach_function :xcb_get_screen_saver_reply, [:pointer, :uint32, :pointer], :pointer
  # Установка заставки экрана
  attach_function :xcb_set_screen_saver, [:pointer, :int16, :int16, :uint8, :uint8], VoidCookie
  
  # === ФУНКЦИИ РАСШИРЕНИЙ ===
  
  # Запрос расширения
  attach_function :xcb_query_extension, [:pointer, :uint16, :string], :uint32
  # Получение ответа расширения
  attach_function :xcb_query_extension_reply, [:pointer, :uint32, :pointer], :pointer
  # Список расширений
  attach_function :xcb_list_extensions, [:pointer], VoidCookie
  # Получение ответа списка расширений
  attach_function :xcb_list_extensions_reply, [:pointer, :uint32, :pointer], :pointer
  
  # === ФУНКЦИИ УТИЛИТ ===
  
  # Парсинг строки дисплея
  attach_function :xcb_parse_display, [:string, :pointer, :pointer, :pointer], :int
  # Получение максимальной длины запроса
  attach_function :xcb_get_maximum_request_length, [:pointer], :uint32
  # Предварительная загрузка максимальной длины запроса
  attach_function :xcb_prefetch_maximum_request_length, [:pointer], :void
  # Общее количество прочитанных байт
  attach_function :xcb_total_read, [:pointer], :uint64
  # Общее количество записанных байт
  attach_function :xcb_total_written, [:pointer], :uint64
  
  # === ФУНКЦИИ СПЕЦИАЛЬНЫХ СОБЫТИЙ ===
  
  # Регистрация для специальных событий
  attach_function :xcb_register_for_special_xge, [:pointer, :pointer, :uint32, :pointer], :pointer
  # Отмена регистрации специальных событий
  attach_function :xcb_unregister_for_special_event, [:pointer, :pointer], :void
  # Ожидание специального события
  attach_function :xcb_wait_for_special_event, [:pointer, :pointer], :pointer
  # Проверка специального события
  attach_function :xcb_poll_for_special_event, [:pointer, :pointer], :pointer
  
  # === ФУНКЦИИ РАСШИРЕНИЙ ДАННЫХ ===
  
  # Получение данных расширения
  attach_function :xcb_get_extension_data, [:pointer, :pointer], :pointer
  # Предварительная загрузка данных расширения
  attach_function :xcb_prefetch_extension_data, [:pointer, :pointer], :void
  
  # === ФУНКЦИИ СОКЕТОВ ===
  
  # Подключение по файловому дескриптору
  attach_function :xcb_connect_to_fd, [:int, :pointer], :pointer
  # Отправка файлового дескриптора
  attach_function :xcb_send_fd, [:pointer, :int], :void
  # Взятие сокета
  attach_function :xcb_take_socket, [:pointer, :pointer, :pointer, :int, :pointer], :int
  # Запись вектора
  attach_function :xcb_writev, [:pointer, :pointer, :int, :uint64], :int
  
  # === ФУНКЦИИ БОЛЬШИХ ЗАПРОСОВ ===
  
  # Включение больших запросов
  attach_function :xcb_big_requests_enable, [:pointer], :uint32
  # Получение ответа больших запросов
  attach_function :xcb_big_requests_enable_reply, [:pointer, :uint32, :pointer], :pointer
  # Включение больших запросов без проверки
  attach_function :xcb_big_requests_enable_unchecked, [:pointer], :uint32
  
  # === ФУНКЦИИ XC-MISC РАСШИРЕНИЯ ===
  
  # Получение версии XC-MISC
  attach_function :xcb_xc_misc_get_version, [:pointer, :uint32, :uint32], :uint32
  # Получение ответа версии XC-MISC
  attach_function :xcb_xc_misc_get_version_reply, [:pointer, :uint32, :pointer], :pointer
  # Получение версии XC-MISC без проверки
  attach_function :xcb_xc_misc_get_version_unchecked, [:pointer, :uint32, :uint32], :uint32
  # Получение диапазона XID
  attach_function :xcb_xc_misc_get_xid_range, [:pointer], :uint32
  # Получение ответа диапазона XID
  attach_function :xcb_xc_misc_get_xid_range_reply, [:pointer, :uint32, :pointer], :pointer
  # Получение диапазона XID без проверки
  attach_function :xcb_xc_misc_get_xid_range_unchecked, [:pointer], :uint32
  # Получение списка XID
  attach_function :xcb_xc_misc_get_xid_list, [:pointer, :uint32, :uint32], :uint32
  # Получение ответа списка XID
  attach_function :xcb_xc_misc_get_xid_list_reply, [:pointer, :uint32, :pointer], :pointer
  # Получение списка XID без проверки
  attach_function :xcb_xc_misc_get_xid_list_unchecked, [:pointer, :uint32, :uint32], :uint32
  
  # === ФУНКЦИИ УТИЛИТ ===
  
  # Подсчет единичных битов
  attach_function :xcb_popcount, [:uint32], :int
  # Сумма элементов
  attach_function :xcb_sumof, [:pointer, :int], :int
  
  # === ТИПЫ УКАЗАТЕЛЕЙ ===
  
  typedef :pointer, :xcb_connection_t
  typedef :pointer, :xcb_generic_event_t
  typedef :pointer, :xcb_generic_reply_t
  typedef :pointer, :xcb_generic_error_t
  typedef :pointer, :xcb_void_cookie_t
  typedef :pointer, :xcb_special_event_t
  typedef :pointer, :xcb_extension_t
  typedef :pointer, :xcb_setup_t
  typedef :pointer, :xcb_screen_t
  typedef :pointer, :xcb_visualtype_t
  typedef :pointer, :xcb_depth_t
  typedef :pointer, :xcb_format_t
  typedef :pointer, :xcb_atom_t
  typedef :pointer, :xcb_window_t
  typedef :pointer, :xcb_drawable_t
  typedef :pointer, :xcb_fontable_t
  typedef :pointer, :xcb_gcontext_t
  typedef :pointer, :xcb_colormap_t
  typedef :pointer, :xcb_cursor_t
  typedef :pointer, :xcb_pixmap_t
  typedef :pointer, :xcb_font_t
  typedef :pointer, :xcb_visualid_t
  typedef :pointer, :xcb_timestamp_t
  typedef :pointer, :xcb_keysym_t
  typedef :pointer, :xcb_keycode_t
  typedef :pointer, :xcb_keycode32_t
  typedef :pointer, :xcb_button_t
  typedef :pointer, :xcb_point_t
  typedef :pointer, :xcb_rectangle_t
  typedef :pointer, :xcb_arc_t
  typedef :pointer, :xcb_segment_t
  typedef :pointer, :xcb_char2b_t
  typedef :pointer, :xcb_charinfo_t
  typedef :pointer, :xcb_fontprop_t
  typedef :pointer, :xcb_str_t
  typedef :pointer, :xcb_timecoord_t
  typedef :pointer, :xcb_rgb_t
  typedef :pointer, :xcb_coloritem_t
  typedef :pointer, :xcb_host_t
  typedef :pointer, :xcb_client_message_data_t
end 