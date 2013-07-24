win32.js is a Win32 wrapper for [Emscripten][].

# Run

You need no Windows to run win32.js project.

1.  Download and extract MinGW [w32api][] and [mingw-rt][].
2.  Install [Emscripten][]. Note that it requires [clang][] 3.2 and [nodejs][].
    It is really boring to build llvm/clang by yourself;
    use a prebuilt package if available.
    -   For Windows, You may use [clang-win32][] binary.
3.  `make`. You'll see some javascript files are `src/`.
4.  `make examples`. It will build `examples/hello.cpp` to
    `examples/hello.js`.
5.  Open `examples/hello.html` using modern web browser.

[w32api]: http://sourceforge.net/projects/mingw/files/MinGW/Base/w32api/
[mingw-rt]: http://sourceforge.net/projects/mingw/files/MinGW/Base/mingw-rt/
[clang-win32]: http://www.ishani.org/web/articles/code/clang-win32/
[nodejs]: http://nodejs.org/
[Emscripten]: http://emscripten.org/
[clang]: http://llvm.org/releases/download.html
