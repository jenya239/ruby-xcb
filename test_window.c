#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    xcb_connection_t *connection;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_gcontext_t gc;
    
    // Подключение к X серверу
    connection = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(connection)) {
        printf("Ошибка подключения к X серверу\n");
        return 1;
    }
    
    // Получение экрана
    screen = xcb_setup_roots_iterator(xcb_get_setup(connection)).data;
    
    // Создание окна
    window = xcb_generate_id(connection);
    xcb_create_window(connection,
                      XCB_COPY_FROM_PARENT,
                      window,
                      screen->root,
                      200, 200, 400, 300,
                      2,
                      XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual,
                      0, NULL);
    
    // Показ окна
    xcb_map_window(connection, window);
    xcb_flush(connection);
    
    printf("Окно создано! ID: %d\n", window);
    printf("Нажмите Enter для закрытия...\n");
    getchar();
    
    // Закрытие
    xcb_destroy_window(connection, window);
    xcb_flush(connection);
    xcb_disconnect(connection);
    
    return 0;
} 