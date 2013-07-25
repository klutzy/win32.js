class System
    constructor: (@desktop) ->
        @mq = []
        @classes = {}
        @windows = {}

        @active_window = null

        @next_handle = 1

    alloc_handle: ->
        handle = @next_handle
        @next_handle += 1
        return handle

    main_loop: () =>
        console.log("System.main_loop", @mq)
        while @mq.length > 0
            msg = delete @mq[0]
            @send_msg(msg)
        setTimeout(@main_loop, 500)

    send_msg: (msg) ->
        win = @windows[msg.hwnd]
        if win == null
            return
        ret = win.on_proc(msg.msg, msg.w, msg.l)

        return ret

    post_msg: (msg) ->
        @mq.push(msg)
        return 0

system = new System(window.Win32.desktop)
window.Win32.system = system # EXPORT

class Class
    constructor: (@clsname, @wnd_proc) ->

window.Win32.Class = Class # EXPORT

class Window
    constructor: (@hwnd, @clsname, @name, @style, \
    @x, @y, @w, @h, @parent, @m, @i, @param, @exstyle) ->

        @cls = system.classes[@clsname] or null
        console.log("clsname:", @clsname, @cls)

        @cmd_show = -1

        # CW_USEDEFAULT
        if @x == -2147483648
            @x = 0
        if @y == -2147483648
            @y = 0
        if @w == -2147483648
            @w = 0
        if @h == -2147483648
            @h = 0

    css: (c) ->
        me = $("#hwnd-#{@hwnd}")
        console.log("css:", c, me)
        if me
            me.css(c)

    reshape: ->
        me = $("#hwnd-#{@hwnd}")
        if me == null
            return

        console.log("style", @style)
        is_vis = @style & 0x10000000
        dis = 'block'
        if !is_vis
            dis = 'none'
        @css({
            display: dis,
            width: @w, height: @h, top: @y, left: @x,
        })

    def_proc: (m, w, l) ->
        switch m
            when 0x0001 # WM_CREATE
                return 0
            when 0x0010 # WM_CLOSE
                @destroy()
                return 0
        return 0

    destroy: ->
        @on_proc(0x0002, 0, 0) # WM_DESTROY
        @on_proc(0x0082, 0, 0) # WM_NCDESTROY
        delete system.windows[@hwnd]
        return 1

    on_proc: (m, w, l) ->
        console.log("on_proc:", m, w, l, @cls, "hwnd:", @hwnd)
        ret = 0
        if @cls and @cls.wnd_proc
            func = FUNCTION_TABLE[@cls.wnd_proc]
            if func
                ret = func(@hwnd, m, w, l)
        else
            ret = @def_proc(m, w, l)
        @on_after_proc(m, w, l, ret)
        return ret

    on_after_proc: (m, w, l, ret) ->
        # ok, wnd_proc did something.
        # e.g. if I agreed to WM_CLOSE, do on_close.
        console.log("on_after_proc", m, w, l, ret)
        switch m
            when 0x0001 # WM_CREATE
                if ret == 0
                    @on_create()
            when 0x0002 # WM_DESTORY
                @on_destroy()
            when 0x0003 # WM_MOVE
                @on_move(l & 0xFFFF, l >> 16)
            when 0x0005 # WM_SIZE
                @on_size(l & 0xFFFF, l >> 16)
            when 0x0018 # WM_SHOW
                @on_show()

        @reshape()
        return ret

    on_create: () ->
        me = null
        if !@cls
            console.log("clss:", @clsname)
            switch @clsname
                when "EDIT"
                    me = $("<input type='text' id='hwnd-#{@hwnd}' value='#{@name}' />")
                when "BUTTON"
                    me = $("<input type='button' id='hwnd-#{@hwnd}' value='#{@name}' />")

        else
            title_bar = $("""
<div class="title-bar">
    <div class="title-icon"></div>
    <div class="title">#{@name}</div>
    <div class="title-button-group">
        <div class="title-button minimize"></div>
        <div class="title-button maximize"></div>
        <div class="title-button close"></div>
    </div>
</div>""")

            me = $("<div class='window' id='hwnd-#{@hwnd}'/>")
            me.append(title_bar)

        parent = system.desktop
        console.log("@parent:", @parent)
        if @parent
            parent = $("#hwnd-#{@parent.hwnd}")
        else
            system.active_window = this
            me.children('.title-bar').addClass('ui-selected')
        console.log("on_create:", me, parent)
        console.log("hwnd", @hwnd)
        ret = parent.append(me)

        if @cls
            me = $("#hwnd-#{@hwnd}")
            me.children(".title-bar").children(".title-button-group").children(".title-button.close").click =>
                @on_proc(0x0010, 0, 0)
            me.draggable({
                handle: ".title",
                drag: (e, u) =>
                    x = u.position.left
                    y = u.position.top
                    console.log("drag:", x, y)
                    @on_proc(0x0003, 0, x | (y << 16)) # WM_MOVE
            })
            me.resizable({
                handles: "all",
                minWidth: parseInt(me.css( "min-width" )),
                minHeight: parseInt(me.css( "min-height" )),
                resize: (e, u) =>
                    x = u.position.left
                    y = u.position.top
                    w = u.size.width
                    h = u.size.height
                    console.log("resize:", x, y, w, h)
                    @on_proc(0x0005, 0, w | (h << 16)) # WM_SIZE
                    @on_proc(0x0003, 0, x | (y << 16)) # WM_MOVE
            })
        else
            switch @clsname
                when "BUTTON"
                    me.click =>
                        # XXX we must make button_wnd_proc() for this
                        @parent.on_proc(0x0111, @m, 0) # WM_COMMAND


    on_destroy: ->
        me = $("#hwnd-#{@hwnd}")
        console.log("on_destroy:", me)
        if me
            @css({display: 'none'})
            me.remove()
            console.log(me)

    on_move: (x, y) ->
        @x = x
        @y = y

    on_size: (w, h) ->
        @x += (@w - w)
        @y += (@h - h)
        @w = w
        @h = h

    on_show: () ->
        console.log("on_show:", @cmd_show, @style)
        if @cmd_show != 0
            @style |= 0x10000000
        else
            @style &= ~0x10000000

        @cmd_show = 0
        console.log("-> ", @cmd_show, @style)

window.Win32.Window = Window # EXPORT
