// inject-once.cpp — LoadLibrary TaskbarClear.dll into explorer.exe, then exit.
// No resident process. RunLevel must be Limited (same integrity as Explorer).

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <psapi.h>
#include <shlwapi.h>
#include <stdio.h>
#include <string>

#pragma comment(lib, "psapi.lib")
#pragma comment(lib, "shlwapi.lib")

static void Fail(const char* msg, DWORD err = GetLastError())
{
    fprintf(stderr, "ERREUR: %s (GetLastError=%lu)\n", msg, err);
}

static std::wstring GetDllPath()
{
    wchar_t exePath[MAX_PATH];
    if (!GetModuleFileNameW(nullptr, exePath, MAX_PATH)) {
        return L"";
    }
    std::wstring path(exePath);
    size_t slash = path.find_last_of(L"\\/");
    if (slash == std::wstring::npos) {
        return L"";
    }
    return path.substr(0, slash + 1) + L"TaskbarClear.dll";
}

static bool IsTrustedDllPath(const std::wstring& dllPath)
{
    wchar_t exePath[MAX_PATH];
    if (!GetModuleFileNameW(nullptr, exePath, MAX_PATH)) {
        return false;
    }

    wchar_t exeDir[MAX_PATH];
    wcscpy_s(exeDir, exePath);
    if (!PathRemoveFileSpecW(exeDir)) {
        return false;
    }

    wchar_t resolvedDll[MAX_PATH];
    if (!GetFullPathNameW(dllPath.c_str(), MAX_PATH, resolvedDll, nullptr)) {
        return false;
    }

    if (!PathFileExistsW(resolvedDll)) {
        return false;
    }

    if (_wcsicmp(PathFindFileNameW(resolvedDll), L"TaskbarClear.dll") != 0) {
        return false;
    }

    wchar_t dllDir[MAX_PATH];
    wcscpy_s(dllDir, resolvedDll);
    if (!PathRemoveFileSpecW(dllDir)) {
        return false;
    }

    return _wcsicmp(exeDir, dllDir) == 0;
}

static DWORD FindExplorerPid()
{
    HWND tray = FindWindowW(L"Shell_TrayWnd", nullptr);
    if (!tray) {
        return 0;
    }
    DWORD pid = 0;
    GetWindowThreadProcessId(tray, &pid);
    return pid;
}

static bool AlreadyLoaded(DWORD pid)
{
    HANDLE hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, pid);
    if (!hProcess) {
        return false;
    }

    HMODULE modules[512];
    DWORD needed = 0;
    if (!EnumProcessModules(hProcess, modules, sizeof(modules), &needed)) {
        CloseHandle(hProcess);
        return false;
    }

    const DWORD count = needed / sizeof(HMODULE);
    wchar_t modulePath[MAX_PATH];
    for (DWORD i = 0; i < count; ++i) {
        if (GetModuleFileNameExW(hProcess, modules[i], modulePath, MAX_PATH) &&
            wcsstr(modulePath, L"TaskbarClear.dll")) {
            CloseHandle(hProcess);
            return true;
        }
    }

    CloseHandle(hProcess);
    return false;
}

static bool Inject(DWORD pid, const std::wstring& dllPath)
{
    HANDLE hProcess = OpenProcess(
        PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION |
        PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ,
        FALSE,
        pid);
    if (!hProcess) {
        Fail("OpenProcess(explorer)");
        return false;
    }

    size_t bytes = (dllPath.size() + 1) * sizeof(wchar_t);
    LPVOID remote = VirtualAllocEx(hProcess, nullptr, bytes, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (!remote) {
        Fail("VirtualAllocEx");
        CloseHandle(hProcess);
        return false;
    }

    if (!WriteProcessMemory(hProcess, remote, dllPath.c_str(), bytes, nullptr)) {
        Fail("WriteProcessMemory");
        VirtualFreeEx(hProcess, remote, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        return false;
    }

    HMODULE k32 = GetModuleHandleW(L"kernel32.dll");
    auto loadLib = reinterpret_cast<LPTHREAD_START_ROUTINE>(
        GetProcAddress(k32, "LoadLibraryW"));
    if (!loadLib) {
        Fail("GetProcAddress(LoadLibraryW)");
        VirtualFreeEx(hProcess, remote, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        return false;
    }

    HANDLE hThread = CreateRemoteThread(hProcess, nullptr, 0, loadLib, remote, 0, nullptr);
    if (!hThread) {
        Fail("CreateRemoteThread");
        VirtualFreeEx(hProcess, remote, 0, MEM_RELEASE);
        CloseHandle(hProcess);
        return false;
    }

    WaitForSingleObject(hThread, 10000);

    DWORD exitCode = 0;
    GetExitCodeThread(hThread, &exitCode);
    CloseHandle(hThread);
    VirtualFreeEx(hProcess, remote, 0, MEM_RELEASE);
    CloseHandle(hProcess);

    if (exitCode == 0) {
        Fail("LoadLibraryW a retourne NULL dans explorer", 0);
        return false;
    }

    printf("OK  TaskbarClear injecte dans explorer PID %lu (module=0x%lX), sortie.\n",
           pid, exitCode);
    return true;
}

int wmain()
{
    std::wstring dll = GetDllPath();
    if (dll.empty() || !IsTrustedDllPath(dll)) {
        Fail("TaskbarClear.dll introuvable ou chemin non autorise (bin\\ adjacent a inject-once.exe)", 0);
        fprintf(stderr, "Cherche uniquement: <dossier de inject-once.exe>\\TaskbarClear.dll\n");
        return 1;
    }

    // Wait briefly for Shell_TrayWnd at logon
    DWORD pid = 0;
    for (int i = 0; i < 60 && pid == 0; ++i) {
        pid = FindExplorerPid();
        if (!pid) {
            Sleep(500);
        }
    }
    if (!pid) {
        Fail("Shell_TrayWnd / explorer introuvable", 0);
        return 1;
    }

    if (AlreadyLoaded(pid)) {
        printf("OK  TaskbarClear deja charge dans explorer PID %lu, sortie.\n", pid);
        return 0;
    }

    return Inject(pid, dll) ? 0 : 2;
}
