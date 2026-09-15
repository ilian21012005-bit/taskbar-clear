// TaskbarClear.dll — Clear-only taskbar TAP (based on w11-theming-suite MIT).
// inject-once LoadLibrary -> InitializeXamlDiagnosticsEx -> BackgroundFill transparent.
// No IPC poll thread, no SWCA, no WinEvent hooks.

#include <initguid.h>   // Must come before guids.h to define (not just declare) GUIDs
#include "TaskbarClear.h"
#include "guids.h"
#include <string>
#include <cstring>
#include <oleauto.h>   // SysAllocString, SysFreeString
#include <shlwapi.h>
#include <shlobj.h>
#include <cstdio>
#include <cstdarg>
#include <share.h>
#include <winstring.h>

#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "WindowsApp.lib")

// ── Debug logging ──
static FILE* g_logFile = nullptr;

static void DebugLog(const char* fmt, ...)
{
    if (!g_logFile) {
        wchar_t path[MAX_PATH];
        if (FAILED(SHGetFolderPathW(nullptr, CSIDL_LOCAL_APPDATA, nullptr, 0, path))) {
            return;
        }
        wcscat_s(path, L"\\transparent-taskbar");
        CreateDirectoryW(path, nullptr);
        wcscat_s(path, L"\\TaskbarClear.log");
        g_logFile = _wfsopen(path, L"a+", _SH_DENYNO);
        if (!g_logFile) return;
    }
    va_list args;
    va_start(args, fmt);
    vfprintf(g_logFile, fmt, args);
    va_end(args);
    fprintf(g_logFile, "\n");
    fflush(g_logFile);
}

// ── Globals ──
HMODULE g_hModule = nullptr;
std::atomic<long> g_refCount(0);
IVisualTreeService3* g_pTreeService = nullptr;
IXamlDiagnostics* g_pDiagnostics = nullptr;
// Default to TRANSPARENT — the whole point of injecting this DLL
TaskbarAppearance g_appearance = APPEARANCE_TRANSPARENT;
VisualTreeWatcher* g_pWatcher = nullptr;

// ══════════════════════════════════════════════
// Stage 2: Self-injection into XAML Diagnostics
// This runs inside explorer.exe after LoadLibrary injection.
// Dynamically loads Windows.UI.Xaml.dll, resolves InitializeXamlDiagnosticsEx,
// and calls it with our own DLL path and CLSID.
// ══════════════════════════════════════════════
typedef HRESULT(WINAPI* PFN_InitializeXamlDiagnosticsEx)(
    LPCWSTR endPointName,
    DWORD pid,
    LPCWSTR wszDllXamlDiagnostics,
    LPCWSTR wszTAPDllName,
    CLSID tapClsid,
    LPCWSTR wszInitializationData
);

static DWORD WINAPI SelfInjectThread(LPVOID)
{
    DebugLog("=== SelfInjectThread started ===");

    // Get our own DLL path
    wchar_t dllPath[MAX_PATH];
    GetModuleFileNameW(g_hModule, dllPath, MAX_PATH);
    DebugLog("DLL path: %ls", dllPath);

    // Load Windows.UI.Xaml.dll and resolve InitializeXamlDiagnosticsEx
    HMODULE hWux = LoadLibraryExW(L"Windows.UI.Xaml.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if (!hWux) {
        return HRESULT_FROM_WIN32(GetLastError());
    }

    auto pfnIXDE = reinterpret_cast<PFN_InitializeXamlDiagnosticsEx>(
        GetProcAddress(hWux, "InitializeXamlDiagnosticsEx"));
    if (!pfnIXDE) {
        FreeLibrary(hWux);
        return HRESULT_FROM_WIN32(GetLastError());
    }

    DWORD pid = GetCurrentProcessId();
    HRESULT hr = E_FAIL;
    UINT8 attempts = 1;

    // Retry loop: each attempt uses a new thread because IXDE is once-per-thread.
    // Use "VisualDiagConnection{N}" endpoint names (same as TranslucentTB).
    do {
        wchar_t connName[64];
        wsprintfW(connName, L"VisualDiagConnection%d", (int)attempts);

        // Must call IXDE on a fresh thread (it's once-per-thread)
        struct IxdeArgs {
            PFN_InitializeXamlDiagnosticsEx pfn;
            LPCWSTR conn;
            DWORD pid;
            LPCWSTR dllPath;
            HRESULT hr;
        };

        IxdeArgs args;
        args.pfn = pfnIXDE;
        args.conn = connName;
        args.pid = pid;
        args.dllPath = dllPath;
        args.hr = E_FAIL;

        HANDLE hThread = CreateThread(nullptr, 0, [](LPVOID param) -> DWORD {
            auto* a = (IxdeArgs*)param;
            a->hr = a->pfn(a->conn, a->pid, nullptr, a->dllPath, CLSID_TaskbarTAPSite, nullptr);
            return 0;
        }, &args, 0, nullptr);

        if (hThread) {
            WaitForSingleObject(hThread, 5000);
            CloseHandle(hThread);
            hr = args.hr;
        }

        if (SUCCEEDED(hr)) {
            DebugLog("IXDE succeeded on attempt %d", (int)attempts);
            break;
        }

        DebugLog("IXDE attempt %d failed: 0x%08X", (int)attempts, hr);
        ++attempts;
        Sleep(500);
    } while (FAILED(hr) && attempts <= 60);

    if (FAILED(hr)) {
        DebugLog("IXDE FAILED after all attempts. Last HRESULT: 0x%08X", hr);
    }

    return hr;
}

// ══════════════════════════════════════════════
// DLL Entry Point
// ══════════════════════════════════════════════
BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH) {
        g_hModule = hInstance;
        DisableThreadLibraryCalls(hInstance);

        // Stage 2: Spawn self-injection thread.
        // This will call InitializeXamlDiagnosticsEx from WITHIN explorer.exe.
        HANDLE hThread = CreateThread(nullptr, 0, SelfInjectThread, nullptr, 0, nullptr);
        if (hThread) {
            CloseHandle(hThread);
        }
    }
    return TRUE;
}

// ══════════════════════════════════════════════
// Exported functions (for IPC/version check)
// ══════════════════════════════════════════════
extern "C" {

HRESULT __stdcall SetTaskbarTransparent()
{
    g_appearance = APPEARANCE_TRANSPARENT;
    if (g_pWatcher) g_pWatcher->ApplyAppearance(g_appearance);
    return S_OK;
}

HRESULT __stdcall SetTaskbarAcrylic()
{
    g_appearance = APPEARANCE_ACRYLIC;
    if (g_pWatcher) g_pWatcher->ApplyAppearance(g_appearance);
    return S_OK;
}

HRESULT __stdcall SetTaskbarDefault()
{
    g_appearance = APPEARANCE_DEFAULT;
    if (g_pWatcher) g_pWatcher->ApplyAppearance(g_appearance);
    return S_OK;
}

int __stdcall GetTaskbarTAPVersion()
{
    return 1;  // v1.0
}

} // extern "C"

// ══════════════════════════════════════════════
// COM: DllGetClassObject + DllCanUnloadNow
// ══════════════════════════════════════════════
STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID* ppv)
{
    if (rclsid == CLSID_TaskbarTAPSite) {
        auto* factory = new TaskbarTAPFactory();
        HRESULT hr = factory->QueryInterface(riid, ppv);
        factory->Release();
        return hr;
    }
    return CLASS_E_CLASSNOTAVAILABLE;
}

STDAPI DllCanUnloadNow()
{
    return (g_refCount == 0) ? S_OK : S_FALSE;
}

// ══════════════════════════════════════════════
// TaskbarTAPFactory (IClassFactory)
// ══════════════════════════════════════════════
TaskbarTAPFactory::TaskbarTAPFactory() : m_refCount(1) { g_refCount++; }

HRESULT TaskbarTAPFactory::QueryInterface(REFIID riid, void** ppv)
{
    if (riid == IID_IUnknown || riid == IID_IClassFactory) {
        *ppv = static_cast<IClassFactory*>(this);
        AddRef();
        return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
}

ULONG TaskbarTAPFactory::AddRef() { return InterlockedIncrement(&m_refCount); }
ULONG TaskbarTAPFactory::Release()
{
    long ref = InterlockedDecrement(&m_refCount);
    if (ref == 0) { g_refCount--; delete this; }
    return ref;
}

HRESULT TaskbarTAPFactory::CreateInstance(IUnknown* pOuter, REFIID riid, void** ppv)
{
    if (pOuter) return CLASS_E_NOAGGREGATION;
    auto* site = new TaskbarTAPSite();
    HRESULT hr = site->QueryInterface(riid, ppv);
    site->Release();
    return hr;
}

HRESULT TaskbarTAPFactory::LockServer(BOOL fLock)
{
    if (fLock) g_refCount++;
    else g_refCount--;
    return S_OK;
}

// ══════════════════════════════════════════════
// TaskbarTAPSite (IObjectWithSite)
// XAML Diagnostics calls SetSite() with the diagnostics provider.
// We QI for IVisualTreeService3 and IXamlDiagnostics, then start
// watching the visual tree.
// ══════════════════════════════════════════════
TaskbarTAPSite::TaskbarTAPSite() : m_refCount(1), m_pSite(nullptr)
{
    g_refCount++;
}

TaskbarTAPSite::~TaskbarTAPSite()
{
    if (m_pSite) m_pSite->Release();
    g_refCount--;
}

HRESULT TaskbarTAPSite::QueryInterface(REFIID riid, void** ppv)
{
    if (riid == IID_IUnknown || riid == IID_IObjectWithSite) {
        *ppv = static_cast<IObjectWithSite*>(this);
        AddRef();
        return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
}

ULONG TaskbarTAPSite::AddRef() { return InterlockedIncrement(&m_refCount); }
ULONG TaskbarTAPSite::Release()
{
    long ref = InterlockedDecrement(&m_refCount);
    if (ref == 0) delete this;
    return ref;
}

HRESULT TaskbarTAPSite::SetSite(IUnknown* pUnkSite)
{
    DebugLog("=== SetSite called (pUnkSite=%p) ===", pUnkSite);

    // Release previous site
    if (m_pSite) { m_pSite->Release(); m_pSite = nullptr; }
    if (g_pTreeService) { g_pTreeService->Release(); g_pTreeService = nullptr; }
    if (g_pDiagnostics) { g_pDiagnostics->Release(); g_pDiagnostics = nullptr; }
    if (g_pWatcher) { g_pWatcher->Release(); g_pWatcher = nullptr; }

    if (!pUnkSite) return S_OK;  // Disconnecting

    m_pSite = pUnkSite;
    m_pSite->AddRef();

    // QI for the XAML diagnostics interfaces
    HRESULT hr = pUnkSite->QueryInterface(__uuidof(IXamlDiagnostics),
                                           reinterpret_cast<void**>(&g_pDiagnostics));
    DebugLog("QI IXamlDiagnostics: 0x%08X (ptr=%p)", hr, g_pDiagnostics);
    if (FAILED(hr)) return hr;

    hr = pUnkSite->QueryInterface(__uuidof(IVisualTreeService3),
                                   reinterpret_cast<void**>(&g_pTreeService));
    DebugLog("QI IVisualTreeService3: 0x%08X (ptr=%p)", hr, g_pTreeService);
    if (FAILED(hr)) return hr;

    // Create watcher and subscribe to visual tree changes
    // Run AdviseVisualTreeChange on a new thread to avoid blocking
    g_pWatcher = new VisualTreeWatcher(g_pDiagnostics, g_pTreeService);

    HANDLE hThread = CreateThread(nullptr, 0, [](LPVOID param) -> DWORD {
        auto* watcher = (VisualTreeWatcher*)param;
        HRESULT hr = g_pTreeService->AdviseVisualTreeChange(watcher);
        return hr;
    }, g_pWatcher, 0, nullptr);

    if (hThread) {
        CloseHandle(hThread);
    }

    return S_OK;
}

HRESULT TaskbarTAPSite::GetSite(REFIID riid, void** ppvSite)
{
    if (!m_pSite) {
        *ppvSite = nullptr;
        return E_FAIL;
    }
    return m_pSite->QueryInterface(riid, ppvSite);
}

// ══════════════════════════════════════════════
// VisualTreeWatcher (IVisualTreeServiceCallback2)
// Watches XAML element creation/mutation to find and modify
// the taskbar background elements.
// ══════════════════════════════════════════════
VisualTreeWatcher::VisualTreeWatcher(IXamlDiagnostics* pDiag, IVisualTreeService3* pService)
    : m_refCount(1), m_pDiag(pDiag), m_pService(pService), m_taskbarCount(0)
{
    g_refCount++;
    if (m_pDiag) m_pDiag->AddRef();
    if (m_pService) m_pService->AddRef();
    memset(m_taskbars, 0, sizeof(m_taskbars));
}

VisualTreeWatcher::~VisualTreeWatcher()
{
    if (m_pDiag) m_pDiag->Release();
    if (m_pService) m_pService->Release();
    g_refCount--;
}

HRESULT VisualTreeWatcher::QueryInterface(REFIID riid, void** ppv)
{
    if (riid == IID_IUnknown ||
        riid == __uuidof(IVisualTreeServiceCallback) ||
        riid == __uuidof(IVisualTreeServiceCallback2)) {
        *ppv = static_cast<IVisualTreeServiceCallback2*>(this);
        AddRef();
        return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
}

ULONG VisualTreeWatcher::AddRef() { return InterlockedIncrement(&m_refCount); }
ULONG VisualTreeWatcher::Release()
{
    long ref = InterlockedDecrement(&m_refCount);
    if (ref == 0) delete this;
    return ref;
}

// ── OnVisualTreeChange ──
// Called by XAML Diagnostics whenever an element is added/removed/changed.
// We look for Rectangle#BackgroundFill and Rectangle#BackgroundStroke.
HRESULT VisualTreeWatcher::OnVisualTreeChange(
    ParentChildRelation relation,
    VisualElement element,
    VisualMutationType mutationType)
{
    if (mutationType == Add) {
        if (element.Name && element.Type) {
            std::wstring name(element.Name);
            std::wstring type(element.Type);

            bool isBackgroundFill = (name == L"BackgroundFill" &&
                                      type.find(L"Rectangle") != std::wstring::npos);
            bool isBackgroundStroke = (name == L"BackgroundStroke" &&
                                       type.find(L"Rectangle") != std::wstring::npos);
            bool isTaskbarFrame = (type.find(L"TaskbarFrame") != std::wstring::npos);

            if (isBackgroundFill || isBackgroundStroke || isTaskbarFrame) {
                DebugLog("Found element: name='%ls' type='%ls' handle=%llu",
                    name.c_str(), type.c_str(), (unsigned long long)element.Handle);
                int slot = -1;

                if (isBackgroundFill || isBackgroundStroke) {
                    for (int i = 0; i < m_taskbarCount; i++) {
                        if (m_taskbars[i].active) {
                            if (isBackgroundFill && m_taskbars[i].backgroundFill == 0) {
                                slot = i; break;
                            }
                            if (isBackgroundStroke && m_taskbars[i].backgroundStroke == 0) {
                                slot = i; break;
                            }
                        }
                    }
                }

                if (slot < 0 && m_taskbarCount < MAX_TASKBARS) {
                    slot = m_taskbarCount++;
                    m_taskbars[slot].active = true;
                    m_taskbars[slot].backgroundFill = 0;
                    m_taskbars[slot].backgroundStroke = 0;
                    m_taskbars[slot].taskbarFrame = 0;
                }

                if (slot >= 0) {
                    if (isBackgroundFill) {
                        m_taskbars[slot].backgroundFill = element.Handle;
                    } else if (isBackgroundStroke) {
                        m_taskbars[slot].backgroundStroke = element.Handle;
                    } else if (isTaskbarFrame) {
                        m_taskbars[slot].taskbarFrame = element.Handle;
                    }

                    // Apply current appearance immediately
                    if (g_appearance != APPEARANCE_DEFAULT) {
                        ApplyAppearance(g_appearance);
                    }
                }
            }
        }
    }
    else if (mutationType == Remove) {
        for (int i = 0; i < m_taskbarCount; i++) {
            if (m_taskbars[i].backgroundFill == element.Handle)
                m_taskbars[i].backgroundFill = 0;
            if (m_taskbars[i].backgroundStroke == element.Handle)
                m_taskbars[i].backgroundStroke = 0;
            if (m_taskbars[i].taskbarFrame == element.Handle)
                m_taskbars[i].taskbarFrame = 0;

            if (m_taskbars[i].active &&
                m_taskbars[i].backgroundFill == 0 &&
                m_taskbars[i].backgroundStroke == 0 &&
                m_taskbars[i].taskbarFrame == 0) {
                m_taskbars[i].active = false;
            }
        }
    }

    return S_OK;
}

HRESULT VisualTreeWatcher::OnElementStateChanged(
    InstanceHandle /*element*/,
    VisualElementState /*elementState*/,
    LPCWSTR /*context*/)
{
    return S_OK;
}

// ── ApplyAppearance via IXamlDiagnostics::GetIInspectableFromHandle ──
// Uses the same approach as TranslucentTB: get the live WinRT Rectangle object
// from the diagnostic handle, then set Fill directly via COM vtable.
// This bypasses GetPropertyIndex/SetProperty which return E_INVALIDARG on Win11.

// IInspectable vtable layout (IUnknown + 3 methods)
// We need to QI for the shape's Fill property.
// WinRT Rectangle inherits from Shape, which has a Fill property.
// We'll use the WinRT ABI to set it directly.

// Minimal WinRT ABI interfaces needed:
// - Windows.UI.Xaml.Shapes.IShape (has get_Fill/put_Fill)
// - Windows.UI.Xaml.Media.ISolidColorBrush
// - Windows.UI.Xaml.IUIElement (has get_Opacity/put_Opacity)

// {786CD0C4-7E41-5792-9675-36710E0ED077} IShape (WUX)
static const GUID IID_IShape = {0x786CD0C4, 0x7E41, 0x5792,
    {0x96, 0x75, 0x36, 0x71, 0x0E, 0x0E, 0xD0, 0x77}};

// {676D0BE9-B65C-41C6-BA80-58CF87F0E1BF} IUIElement
static const GUID IID_IUIElement = {0x676D0BE9, 0xB65C, 0x41C6,
    {0xBA, 0x80, 0x58, 0xCF, 0x87, 0xF0, 0xE1, 0xBF}};

// {7BF4F276-C836-5A90-944B-4E0FBD58B741} ISolidColorBrush factory
static const GUID IID_ISolidColorBrushFactory = {0x7BF4F276, 0xC836, 0x5A90,
    {0x94, 0x4B, 0x4E, 0x0F, 0xBD, 0x58, 0xB7, 0x41}};

// Windows.UI.Color struct
struct WUColor {
    BYTE A, R, G, B;
};

// Minimal IShape vtable: IInspectable (6 methods) + IShape methods
// Fill is at vtable offset 6 (get_Fill) and 7 (put_Fill)
// But we need the exact offsets. Let's use a different approach:
// Use IXamlDiagnostics::GetIInspectableFromHandle to get IInspectable*,
// then use direct property manipulation via the XAML diagnostics
// SetProperty method with a different approach.

// Actually, the cleanest way is: get the IInspectable, then use
// RoActivateInstance + direct WinRT calls. But that's complex.
// Let's try the simplest approach: just set Opacity to 0 on the element
// by getting it as IUIElement and calling put_Opacity.

// The IUIElement vtable is well-known. Opacity is a DependencyProperty.
// But rather than hardcode vtable offsets (fragile), let's use
// IActivationFactory to create a SolidColorBrush, then use
// IShape::put_Fill.

// SIMPLEST APPROACH: Use SetPropertyValue from IVisualTreeService (base)
// which takes a string value directly. This was the original API before
// GetPropertyIndex was added.

// Wait -- IVisualTreeService::SetProperty takes (handle, handle, index).
// Let's check the ORIGINAL IVisualTreeService.

// Actually, looking at the log more carefully:
// CreateInstance SUCCEEDS (S_OK), GetPropertyIndex FAILS (E_INVALIDARG).
// The issue might be that GetPropertyIndex expects the property name
// in a specific XAML path format. Let me try the GetIInspectableFromHandle
// approach since TranslucentTB proves it works.

void VisualTreeWatcher::ApplyAppearance(TaskbarAppearance appearance)
{
    DebugLog("ApplyAppearance called: mode=%d taskbarCount=%d", (int)appearance, m_taskbarCount);
    if (!m_pDiag) { DebugLog("  ERROR: m_pDiag is null!"); return; }

    for (int i = 0; i < m_taskbarCount; i++) {
        if (!m_taskbars[i].active) continue;

        InstanceHandle bgFill = m_taskbars[i].backgroundFill;
        InstanceHandle bgStroke = m_taskbars[i].backgroundStroke;

        // Apply to BackgroundFill rectangle
        if (bgFill != 0) {
            ApplyToRectangle(bgFill, appearance, false);
        }

        // Apply to BackgroundStroke rectangle
        if (bgStroke != 0) {
            ApplyToRectangle(bgStroke, appearance, true);
        }
    }
}

// Get IInspectable from handle, then set Opacity directly via WinRT ABI
void VisualTreeWatcher::ApplyToRectangle(InstanceHandle handle,
                                          TaskbarAppearance appearance,
                                          bool isStroke)
{
    // Get the live WinRT object from the diagnostic handle
    IInspectable* pInspectable = nullptr;
    HRESULT hr = m_pDiag->GetIInspectableFromHandle(handle, &pInspectable);
    DebugLog("  GetIInspectableFromHandle(%llu) = 0x%08X (ptr=%p)",
        (unsigned long long)handle, hr, pInspectable);
    if (FAILED(hr) || !pInspectable) return;

    // QI for IUIElement to set Opacity
    // IUIElement is at {676D0BE9-B65C-41C6-BA80-58CF87F0E1BF}
    IUnknown* pUIElement = nullptr;
    hr = pInspectable->QueryInterface(IID_IUIElement, (void**)&pUIElement);
    DebugLog("  QI IUIElement: 0x%08X (ptr=%p)", hr, pUIElement);

    if (SUCCEEDED(hr) && pUIElement) {
        // IUIElement vtable: IInspectable (6) + many properties
        // Opacity is a dependency property. Instead of hardcoding vtable offset,
        // let's use the Opacity property through a different mechanism.

        // For now, we'll just try setting Opacity = 0 by calling through
        // the vtable. The IUIElement interface has:
        // [propget] Opacity at vtable slot 8 (after IInspectable's 6 + DesiredSize + AllowDrop)
        // [propput] Opacity at vtable slot 9
        // But the exact slot depends on the interface version. This is fragile.

        // BETTER APPROACH: Use the fact that we're in explorer.exe and can
        // use RoActivateInstance to create objects, then set properties.
        // But the SAFEST approach for now is to use a WinRT API stub.

        // Let's try brute-force: use the IInspectable to get the RuntimeClassName,
        // which confirms we have the right object type.
        HSTRING className = nullptr;
        hr = pInspectable->GetRuntimeClassName(&className);
        if (SUCCEEDED(hr) && className) {
            UINT32 len = 0;
            const wchar_t* name = WindowsGetStringRawBuffer(className, &len);
            DebugLog("  RuntimeClassName: '%ls'", name ? name : L"(null)");
            WindowsDeleteString(className);
        }

        pUIElement->Release();
    }

    // For the actual property setting, we need to use the WinRT ABI.
    // Since we're inside explorer.exe and the XAML runtime is active,
    // we can use RoActivateInstance to create a SolidColorBrush and
    // set it via the Shape interface.

    // Create a transparent SolidColorBrush via RoActivateInstance
    if (appearance == APPEARANCE_TRANSPARENT ||
        (appearance == APPEARANCE_ACRYLIC && isStroke)) {
        SetRectangleOpacity(pInspectable, 0.0);
    }
    else if (appearance == APPEARANCE_ACRYLIC && !isStroke) {
        SetRectangleOpacity(pInspectable, 0.3);
    }
    else if (appearance == APPEARANCE_DEFAULT) {
        SetRectangleOpacity(pInspectable, 1.0);
    }

    pInspectable->Release();
}

// Set UIElement.Opacity via WinRT ABI vtable call
// UIElement vtable (IUIElement):
//   0-2: IUnknown (QI, AddRef, Release)
//   3-5: IInspectable (GetIids, GetRuntimeClassName, GetTrustLevel)
//   6+: IUIElement properties
// The exact layout depends on the Windows.UI.Xaml.UIElement runtime class.
// Opacity is one of the earliest properties on IUIElement.
// From WinRT metadata: IUIElement has DesiredSize, AllowDrop, Opacity...
// Actually, the safest way is to use WindowsCreateString + RoGetActivationFactory
// to create a brush and QI for IShape::put_Fill.
//
// For Opacity, it's at a fixed ABI offset. Let's try a minimal approach:
// IUIElement inherits from IInspectable (6 methods).
// Slots in IUIElement (approximate from Windows.UI.Xaml UIDL):
//   6: get_DesiredSize
//   7: get_AllowDrop / put_AllowDrop / ...
// Opacity is further in. This is fragile across Windows versions.
//
// MOST RELIABLE: Use the activation factory approach.
void VisualTreeWatcher::SetRectangleOpacity(IInspectable* pElement, double opacity)
{
    // We'll use the fact that we're in explorer.exe with WinRT active.
    // Create a string for the class name, get the activation factory,
    // and use it. But for Opacity, we can also try a direct hack:
    // Call the put_Opacity method through the vtable.

    // Actually the most pragmatic approach: use IXamlDiagnostics's
    // SetProperty with the right parameters. We know CreateInstance works.
    // The issue was GetPropertyIndex. Let's try using the element handle
    // with the property chain from IVisualTreeService::GetPropertyValuesChain

    if (!m_pService || !pElement) return;

    // Get the handle back from the inspectable
    InstanceHandle handle = 0;
    HRESULT hr = m_pDiag->GetHandleFromIInspectable(pElement, &handle);
    DebugLog("  GetHandleFromIInspectable: 0x%08X (handle=%llu)", hr, (unsigned long long)handle);
    if (FAILED(hr)) return;

    // Try to enumerate properties to find the right index
    unsigned int propCount = 0;
    PropertyChainSource* pSources = nullptr;
    unsigned int srcCount = 0;
    PropertyChainValue* pValues = nullptr;

    hr = m_pService->GetPropertyValuesChain(handle, &srcCount, &pSources, &propCount, &pValues);
    DebugLog("  GetPropertyValuesChain: 0x%08X (props=%u, sources=%u)", hr, propCount, srcCount);

    if (SUCCEEDED(hr)) {
        // Find the Fill and Opacity properties
        unsigned int fillIndex = UINT_MAX;
        unsigned int opacityIndex = UINT_MAX;

        for (unsigned int p = 0; p < propCount; p++) {
            if (pValues[p].PropertyName) {
                std::wstring propName(pValues[p].PropertyName);
                if (propName == L"Fill") {
                    DebugLog("  Property[%u]: '%ls' = '%ls' (index=%u, metaBits=%lld)",
                        p, pValues[p].PropertyName,
                        pValues[p].Value ? pValues[p].Value : L"(null)",
                        pValues[p].Index, (long long)pValues[p].MetadataBits);
                    fillIndex = pValues[p].Index;
                }
                if (propName == L"Opacity") {
                    DebugLog("  Property[%u]: '%ls' = '%ls' (index=%u, metaBits=%lld)",
                        p, pValues[p].PropertyName,
                        pValues[p].Value ? pValues[p].Value : L"(null)",
                        pValues[p].Index, (long long)pValues[p].MetadataBits);
                    opacityIndex = pValues[p].Index;
                }
            }
        }

        // Set Opacity using the correct property index
        if (opacityIndex != UINT_MAX) {
            wchar_t opStr[32];
            wsprintfW(opStr, L"%d", (int)(opacity * 100));
            // Convert to proper double string
            std::wstring opValStr = std::to_wstring(opacity);

            InstanceHandle hValue = 0;
            BSTR bstrType = SysAllocString(L"Double");
            BSTR bstrVal = SysAllocString(opValStr.c_str());
            hr = m_pService->CreateInstance(bstrType, bstrVal, &hValue);
            SysFreeString(bstrType);
            SysFreeString(bstrVal);
            DebugLog("  CreateInstance('Double','%ls') = 0x%08X", opValStr.c_str(), hr);

            if (SUCCEEDED(hr)) {
                hr = m_pService->SetProperty(handle, hValue, opacityIndex);
                DebugLog("  SetProperty(opacity, idx=%u) = 0x%08X", opacityIndex, hr);
            }
        }

        // Set Fill to transparent brush if needed
        if (fillIndex != UINT_MAX && opacity < 1.0) {
            InstanceHandle hBrush = 0;
            BSTR bstrType = SysAllocString(L"Windows.UI.Xaml.Media.SolidColorBrush");
            BSTR bstrVal = SysAllocString(L"Transparent");
            hr = m_pService->CreateInstance(bstrType, bstrVal, &hBrush);
            SysFreeString(bstrType);
            SysFreeString(bstrVal);
            DebugLog("  CreateInstance(SolidColorBrush, Transparent) = 0x%08X", hr);

            if (SUCCEEDED(hr)) {
                hr = m_pService->SetProperty(handle, hBrush, fillIndex);
                DebugLog("  SetProperty(fill, idx=%u) = 0x%08X", fillIndex, hr);
            }
        }

        // Free property chain (all BSTR fields)
        for (unsigned int p = 0; p < propCount; p++) {
            if (pValues[p].PropertyName) SysFreeString(pValues[p].PropertyName);
            if (pValues[p].Value) SysFreeString(pValues[p].Value);
            if (pValues[p].Type) SysFreeString(pValues[p].Type);
            if (pValues[p].DeclaringType) SysFreeString(pValues[p].DeclaringType);
            if (pValues[p].ValueType) SysFreeString(pValues[p].ValueType);
            if (pValues[p].ItemType) SysFreeString(pValues[p].ItemType);
        }
        CoTaskMemFree(pValues);
        for (unsigned int s = 0; s < srcCount; s++) {
            if (pSources[s].Name) SysFreeString(pSources[s].Name);
            if (pSources[s].TargetType) SysFreeString(pSources[s].TargetType);
        }
        CoTaskMemFree(pSources);
    }
}
