#include <xcb/xcb.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    xcb_connection_t *conn;
    xcb_screen_t *screen;
    xcb_window_t window;
    xcb_colormap_t colormap;
    xcb_gcontext_t gc_red, gc_green, gc_blue;

    printf("=== XCB Color Test ===\n");

    // Подключение
    conn = xcb_connect(NULL, NULL);
    if (xcb_connection_has_error(conn)) {
        printf("❌ Ошибка подключения к X серверу\n");
        return 1;
    }

    screen = xcb_setup_roots_iterator(xcb_get_setup(conn)).data;
    printf("✅ Подключен к экрану: %dx%d, глубина: %d\n", 
           screen->width_in_pixels, screen->height_in_pixels, screen->root_depth);

    // Создание окна
    uint32_t values[] = { XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS };
    window = xcb_generate_id(conn);
    xcb_create_window(conn, XCB_COPY_FROM_PARENT, window, screen->root,
                      100, 100, 400, 300, 2, XCB_WINDOW_CLASS_INPUT_OUTPUT,
                      screen->root_visual, XCB_CW_EVENT_MASK, values);

    // Создание колормапа
    colormap = xcb_generate_id(conn);
    xcb_create_colormap(conn, XCB_COLORMAP_ALLOC_NONE, colormap, window, screen->root_visual);
    printf("✅ Колормап создан: %d\n", colormap);

    // Выделение красного цвета (R=255, G=0, B=0)
    xcb_alloc_color_cookie_t red_cookie = xcb_alloc_color(conn, colormap, 65535, 0, 0);
    xcb_alloc_color_reply_t *red_reply = xcb_alloc_color_reply(conn, red_cookie, NULL);
    if (red_reply) {
        printf("✅ Красный цвет: pixel=%d, RGB=(%d,%d,%d)\n", 
               red_reply->pixel, red_reply->red, red_reply->green, red_reply->blue);
        
        // GC для красного
        uint32_t red_vals[] = { red_reply->pixel };
        gc_red = xcb_generate_id(conn);
        xcb_create_gc(conn, gc_red, window, XCB_GC_FOREGROUND, red_vals);
        free(red_reply);
    }

    // Выделение зеленого цвета (R=0, G=255, B=0)
    xcb_alloc_color_cookie_t green_cookie = xcb_alloc_color(conn, colormap, 0, 65535, 0);
    xcb_alloc_color_reply_t *green_reply = xcb_alloc_color_reply(conn, green_cookie, NULL);
    if (green_reply) {
        printf("✅ Зеленый цвет: pixel=%d, RGB=(%d,%d,%d)\n",
               green_reply->pixel, green_reply->red, green_reply->green, green_reply->blue);
        
        // GC для зеленого
        uint32_t green_vals[] = { green_reply->pixel };
        gc_green = xcb_generate_id(conn);
        xcb_create_gc(conn, gc_green, window, XCB_GC_FOREGROUND, green_vals);
        free(green_reply);
    }

    // Выделение синего цвета (R=0, G=0, B=255)
    xcb_alloc_color_cookie_t blue_cookie = xcb_alloc_color(conn, colormap, 0, 0, 65535);
    xcb_alloc_color_reply_t *blue_reply = xcb_alloc_color_reply(conn, blue_cookie, NULL);
    if (blue_reply) {
        printf("✅ Синий цвет: pixel=%d, RGB=(%d,%d,%d)\n",
               blue_reply->pixel, blue_reply->red, blue_reply->green, blue_reply->blue);
        
        // GC для синего
        uint32_t blue_vals[] = { blue_reply->pixel };
        gc_blue = xcb_generate_id(conn);
        xcb_create_gc(conn, gc_blue, window, XCB_GC_FOREGROUND, blue_vals);
        free(blue_reply);
    }

    // Показ окна
    xcb_map_window(conn, window);
    xcb_flush(conn);
    printf("✅ Окно показано с цветными прямоугольниками\n");

    // Цикл событий с рисованием
    xcb_generic_event_t *event;
    printf("🎯 Нажмите любую клавишу для выхода\n");
    
    while ((event = xcb_wait_for_event(conn))) {
        uint8_t type = event->response_type & ~0x80;
        
        if (type == XCB_EXPOSE) {
            // Очистка окна белым фоном
            xcb_clear_area(conn, 0, window, 0, 0, 400, 300);
            
            // Рисование цветных прямоугольников
            xcb_rectangle_t red_rect = { 50, 50, 100, 80 };
            xcb_poly_fill_rectangle(conn, window, gc_red, 1, &red_rect);
            
            xcb_rectangle_t green_rect = { 200, 50, 100, 80 };
            xcb_poly_fill_rectangle(conn, window, gc_green, 1, &green_rect);
            
            xcb_rectangle_t blue_rect = { 125, 150, 100, 80 };
            xcb_poly_fill_rectangle(conn, window, gc_blue, 1, &blue_rect);
            
            xcb_flush(conn);
            printf("🎨 Окно очищено и цветные прямоугольники нарисованы\n");
        } 
        else if (type == XCB_KEY_PRESS) {
            free(event);
            break;
        }
        free(event);
    }

    // Очистка
    xcb_free_gc(conn, gc_red);
    xcb_free_gc(conn, gc_green);
    xcb_free_gc(conn, gc_blue);
    xcb_free_colormap(conn, colormap);
    xcb_destroy_window(conn, window);
    xcb_disconnect(conn);

    printf("✅ Тест цветов завершен\n");
    return 0;
}