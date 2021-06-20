// termlib-win.dart
//
// Win32-dependent library for interrogating and manipulating the console.
//
// This class provides raw wrappers for the underlying terminal system calls
// that are not available through ANSI mode control sequences, and is not
// designed to be called directly. Package consumers should normally use the
// `Console` class to call these methods.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../termlib.dart';

class TermLibWindows implements TermLib {
  late final int inputHandle;
  late final int outputHandle;

  @override
  int getWindowHeight() {
    final pBufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();
    try {
      GetConsoleScreenBufferInfo(outputHandle, pBufferInfo);

      final windowHeight =
          pBufferInfo.ref.srWindow.Bottom - pBufferInfo.ref.srWindow.Top + 1;
      return windowHeight;
    } finally {
      calloc.free(pBufferInfo);
    }
  }

  @override
  int getWindowWidth() {
    final pBufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();
    try {
      GetConsoleScreenBufferInfo(outputHandle, pBufferInfo);

      final windowWidth =
          pBufferInfo.ref.srWindow.Right - pBufferInfo.ref.srWindow.Left + 1;
      return windowWidth;
    } finally {
      calloc.free(pBufferInfo);
    }
  }

  @override
  int setWindowHeight(int height) {
    final pBufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();

    try {
      final bufferInfo = pBufferInfo.ref;
      final originalwindowHeight =
          bufferInfo.srWindow.Bottom - bufferInfo.srWindow.Top + 1;

      var result = originalwindowHeight;
      if (GetConsoleScreenBufferInfo(outputHandle, pBufferInfo) != 0) {
        final pWindowRect = calloc<SMALL_RECT>();
        pWindowRect.ref.Bottom = height - originalwindowHeight;
        if (SetConsoleWindowInfo(outputHandle, 0, pWindowRect) != 0) {
          result = height;
        }
        free(pWindowRect);
      }
      return result;
    } finally {
      calloc.free(pBufferInfo);
    }
  }

  @override
  int setWindowWidth(int width) {
    final pBufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();

    try {
      final bufferInfo = pBufferInfo.ref;
      final originalWindowWidth =
          bufferInfo.srWindow.Right - bufferInfo.srWindow.Left + 1;
      var result = originalWindowWidth;
      if (GetConsoleScreenBufferInfo(outputHandle, pBufferInfo) != 0) {
        final pWindowRect = calloc<SMALL_RECT>();
        pWindowRect.ref.Right = width - originalWindowWidth;
        if (SetConsoleWindowInfo(outputHandle, 0, pWindowRect) != 0) {
          result = width;
        }
        free(pWindowRect);
      }
      return result;
    } finally {
      free(pBufferInfo);
    }
  }

  @override
  void enableRawMode() {
    final dwMode = (~ENABLE_ECHO_INPUT) &
        (~ENABLE_ECHO_INPUT) &
        (~ENABLE_PROCESSED_INPUT) &
        (~ENABLE_LINE_INPUT) &
        (~ENABLE_WINDOW_INPUT);
    SetConsoleMode(inputHandle, dwMode);
  }

  @override
  void disableRawMode() {
    final dwMode = ENABLE_ECHO_INPUT &
        ENABLE_EXTENDED_FLAGS &
        ENABLE_INSERT_MODE &
        ENABLE_LINE_INPUT &
        ENABLE_MOUSE_INPUT &
        ENABLE_PROCESSED_INPUT &
        ENABLE_QUICK_EDIT_MODE &
        ENABLE_VIRTUAL_TERMINAL_INPUT;
    SetConsoleMode(inputHandle, dwMode);
  }

  void hideCursor() {
    final lpConsoleCursorInfo = calloc<CONSOLE_CURSOR_INFO>()..ref.bVisible = 0;
    try {
      SetConsoleCursorInfo(outputHandle, lpConsoleCursorInfo);
    } finally {
      calloc.free(lpConsoleCursorInfo);
    }
  }

  void showCursor() {
    final lpConsoleCursorInfo = calloc<CONSOLE_CURSOR_INFO>()..ref.bVisible = 1;
    try {
      SetConsoleCursorInfo(outputHandle, lpConsoleCursorInfo);
    } finally {
      calloc.free(lpConsoleCursorInfo);
    }
  }

  void clearScreen() {
    final pBufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();
    final pCharsWritten = calloc<Uint32>();
    final origin = calloc<COORD>();
    try {
      final bufferInfo = pBufferInfo.ref;
      GetConsoleScreenBufferInfo(outputHandle, pBufferInfo);

      final consoleSize = bufferInfo.dwSize.X * bufferInfo.dwSize.Y;

      FillConsoleOutputCharacter(outputHandle, ' '.codeUnitAt(0), consoleSize,
          origin.ref, pCharsWritten);

      GetConsoleScreenBufferInfo(outputHandle, pBufferInfo);

      FillConsoleOutputAttribute(outputHandle, bufferInfo.wAttributes,
          consoleSize, origin.ref, pCharsWritten);

      SetConsoleCursorPosition(outputHandle, origin.ref);
    } finally {
      calloc.free(origin);
      calloc.free(pCharsWritten);
      calloc.free(pBufferInfo);
    }
  }

  void setCursorPosition(int x, int y) {
    final coord = calloc<COORD>()
      ..ref.X = x
      ..ref.Y = y;
    try {
      SetConsoleCursorPosition(outputHandle, coord.ref);
    } finally {
      calloc.free(coord);
    }
  }

  TermLibWindows() {
    outputHandle = GetStdHandle(STD_OUTPUT_HANDLE);
    inputHandle = GetStdHandle(STD_INPUT_HANDLE);
  }
}
