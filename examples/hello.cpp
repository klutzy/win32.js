#ifndef UNICODE
#define UNICODE
#endif

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>

#ifdef EMSCRIPTEN
extern "C" void emscripten_win32_loop();
#endif

HWND main_win;
HWND hello_edit;
HWND hello_button;

enum {
    IDC_HELLO_BUTTON = 101,
};

extern "C"
long CALLBACK wnd_proc(HWND wnd, UINT msg, WPARAM wparam, LPARAM lparam) {
    switch (msg) {
        case WM_CREATE: {
            return 0;
        }
        break;

        case WM_COMMAND: {
            switch (LOWORD(wparam)) {
                case IDC_HELLO_BUTTON: {
                    wchar_t msg[100] = {0,};
                    GetWindowText(hello_edit, msg, 100);
                    MessageBox(wnd, msg, L"title", 0);
                }
                break;
            }
        }
        break;

        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(wnd, &ps);
            TextOut(hdc, 100, 300, L"WM_PAINT", 8);
            EndPaint(wnd, &ps);
            return 0;
        }
        break;

        case WM_DESTROY: {
            PostQuitMessage(0);
            return 0;
        }
        break;
    }

    return DefWindowProc(wnd, msg, wparam, lparam);
}

extern "C"
int CALLBACK WinMain(HINSTANCE inst, HINSTANCE prev_inst, char *cmd_line, int cmd_show) {
    static const wchar_t *cls_name = L"MainClass";

    WNDCLASS cls = {};
    cls.lpfnWndProc = wnd_proc;
    cls.hInstance = inst;
    cls.lpszClassName = cls_name;
    cls.hCursor = LoadCursor(NULL, IDC_ARROW);

    int res = RegisterClass(&cls);

    main_win = CreateWindow(cls_name, L"HelloWorld", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 700, 500, NULL, NULL, inst, 0);
    hello_edit = CreateWindow(L"EDIT", L"Hello", WS_CHILD | WS_VISIBLE, 0, 0, 100, 30, main_win, NULL, inst, 0);
    hello_button = CreateWindow(L"BUTTON", L"World", WS_CHILD | WS_VISIBLE, 120, 0, 100, 30, main_win, (HMENU)IDC_HELLO_BUTTON, inst, 0);

    ShowWindow(main_win, cmd_show);

// https://github.com/kripken/emscripten/wiki/Emscripten-browser-environment
#ifdef EMSCRIPTEN
    emscripten_win32_loop();
#else
    MSG msg = {};
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
#endif
    return 0;
}

#ifdef EMSCRIPTEN
int main() {
    return WinMain(NULL, NULL, NULL, 1);
}
#endif
