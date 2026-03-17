#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include "app_links/app_links_plugin_c_api.h"  

#include <string>

#include "flutter_window.h"
#include "utils.h"

struct WindowSearchParams {
    std::wstring targetTitle;
    HWND foundWindow;
};

BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam) {
    WindowSearchParams* params = reinterpret_cast<WindowSearchParams*>(lParam);
    
    wchar_t className[256];
    if (GetClassName(hwnd, className, 256) > 0) {
        if (wcscmp(className, L"FLUTTER_RUNNER_WIN32_WINDOW") == 0) {
            wchar_t windowTitle[256];
            if (GetWindowText(hwnd, windowTitle, 256) > 0) {
                if (wcsstr(windowTitle, params->targetTitle.c_str()) != nullptr) {
                    params->foundWindow = hwnd;
                    return FALSE; 
                }
            }
        }
    }
    return TRUE;
}

bool SendCommandLineToInstance(HWND hwnd, const wchar_t* command_line) {
  if (!hwnd || !command_line) return false;
  COPYDATASTRUCT cds;
  cds.dwData = 1; 
  cds.cbData = static_cast<DWORD>((wcslen(command_line) + 1) * sizeof(wchar_t));
  cds.lpData = (void*)command_line;
  
  LRESULT result = SendMessage(hwnd, WM_COPYDATA, 0, (LPARAM)&cds);
  return result != 0;
}

bool SendAppLinkToInstance(const std::wstring& title, const wchar_t* command_line) {
    WindowSearchParams params;
    params.targetTitle = title;
    params.foundWindow = nullptr;
    
    EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&params));
    HWND hwnd = params.foundWindow;
    
    if (hwnd) {
        if (command_line && wcslen(command_line) > 0) {
            SendCommandLineToInstance(hwnd, command_line);
        }
        
        SendAppLink(hwnd);
        
        WINDOWPLACEMENT place = { sizeof(WINDOWPLACEMENT) };
        GetWindowPlacement(hwnd, &place);

        switch(place.showCmd) {
            case SW_SHOWMAXIMIZED:
                ShowWindow(hwnd, SW_SHOWMAXIMIZED);
                break;
            case SW_SHOWMINIMIZED:
                ShowWindow(hwnd, SW_RESTORE);
                break;
            default:
                ShowWindow(hwnd, SW_NORMAL);
                break;
        }

        SetWindowPos(0, HWND_TOP, 0, 0, 0, 0, SWP_SHOWWINDOW | SWP_NOSIZE | SWP_NOMOVE);
        SetForegroundWindow(hwnd);


        return true;
    }

    return false;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  
  
  if (command_line && wcsstr(command_line, L"astral://")) {
    if (SendAppLinkToInstance(L"Astral-ng", command_line)) {
      return EXIT_SUCCESS;
    }
  }

  HANDLE hMutex = CreateMutexW(NULL, TRUE, L"AstralAppSingleInstanceMutex");
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND hWnd = NULL;
    EnumWindows(EnumWindowsProc, (LPARAM)&hWnd);
    
    if (hWnd != NULL) {
      if (IsIconic(hWnd)) {
        ShowWindow(hWnd, SW_RESTORE);
      }
      SetForegroundWindow(hWnd);
    }
    CloseHandle(hMutex);
    return 0;
  }

  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Astral-ng", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  CloseHandle(hMutex);
  return EXIT_SUCCESS;
}