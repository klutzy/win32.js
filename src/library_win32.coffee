LibraryWin32 = {
    $Util:
        str_to: (t, $p, len) ->
            i = 0
            while i < t.length
                setValue($p + i*4, t.charCodeAt(i), 'i32')
                i++
            return i

        u16: (ptr, length) ->
            if (ptr == 0)
                return ""
            i = 0
            ret = []
            while (1)
                assert(ptr + i < TOTAL_MEMORY)
                t = getValue(ptr+i*4, 'i32')
                if t == 0 && !length
                    break
                ret.push(t)
                i++
                if length && i == length
                    break

            ret = String.fromCharCode.apply(String, ret)
            return ret

    emscripten_win32_loop: ->
        setTimeout(window.Win32.system.main_loop, 0)

    RegisterClassW: ($cls) ->
        clsname = Util.u16(getValue($cls + 36, 'i32'))
        wnd_proc = getValue($cls + 4)
        cls = new window.Win32.Class(clsname, wnd_proc)
        console.log("RegisterClassW:", cls)
        window.Win32.system.classes[clsname] = cls
        return 0

    DefWindowProcW: (hwnd, m, w, l) ->
        console.log("DefWindowProcW:", hwnd, m, w, l)
        win = window.Win32.system.windows[hwnd]
        if win
            return win.def_proc(m, w, l)
        return 0

    LoadCursorW: (a, b) ->
        console.log("LoadCursorW")

    PostQuitMessage: (n) ->
        console.log("PostQuitMessage")

    PostMessageW: (hwnd, msg, w, l) ->
        return window.Win32.system.post_msg({hwnd: hwnd, msg: msg, w: w, l: l})

    SendMessageW: (hwnd, msg, w, l) ->
        return window.Win32.system.send_msg({hwnd: hwnd, msg: msg, w: w, l: l})

    ShowWindow: (hwnd, cmd_show) ->
        win = window.Win32.system.windows[hwnd]
        console.log("ShowWindow", hwnd, cmd_show, win)
        if win
            l = 0
            if win.cmd_show != -1
                win.cmd_show = cmd_show
            return window.Win32.system.send_msg({hwnd: hwnd, msg: 0x0018, w: 0, l: l})
        return 0

    CreateWindowExW: (exstyle, $clsname, $name, style, x, y, w, h, \
    parent, m, i, param) ->
        clsname = Util.u16($clsname)
        name = Util.u16($name)
        hwnd = window.Win32.system.alloc_handle();

        if parent
            parent = window.Win32.system.windows[parent]
        else
            parent = null
        win = new window.Win32.Window(
            hwnd, clsname, name, style, x, y, w, h,
            parent, m, i, param, exstyle
        )

        window.Win32.system.windows[hwnd] = win;
        #win.on_proc(0x0081, 0, 0) # WM_NCCREATE
        #win.on_proc(0x0083, 0, 0) # WM_NCCALCSIZE
        ret = win.on_proc(0x0001, 0, 0) # WM_CREATE
        if ret == 0
            return hwnd
        else
            return 0

    MessageBoxW: (hwnd, $message, $title, v) ->
        #title = Util.u16($title)
        message = Util.u16($message)
        alert(message)

    GetWindowTextW: (hwnd, $msg, msglen) ->
        win = window.Win32.system.windows[hwnd]
        if !win
            return 0
        msg = win.get_name()
        return Util.str_to(msg, $msg, msglen)

    BeginPaint: (hwnd, $ps) ->
        win = window.Win32.system.windows[hwnd]
        if !win
            return 0
        hdc = window.Win32.system.alloc_handle()
        win.hdc = hdc
        system.dcs[hdc] = win.hwnd
        return hdc

    EndPaint: (hwnd, $ps) ->
        win = window.Win32.system.windows[hwnd]
        if !win
            return 1
        hdc = win.hdc
        delete system.dcs[hdc]
        win.hdc = null
        return 1

    TextOutW: (hdc, x, y, $msg, msglen) ->
        hwnd = window.Win32.system.dcs[hdc]
        win = window.Win32.system.windows[hwnd]
        if !win
            return 0
        msg = Util.u16($msg, msglen)
        win.text_out(x, y, msg)
}

autoAddDeps(LibraryWin32, '$Util')
mergeInto(LibraryManager.library, LibraryWin32)
