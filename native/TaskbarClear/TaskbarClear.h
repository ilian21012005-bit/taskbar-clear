// TaskbarTAP.h — Minimal Taskbar Appearance Plugin for w11-theming-suite
// Implements IObjectWithSite + IVisualTreeServiceCallback2 to modify the
// XAML visual tree of the Windows 11 taskbar (Rectangle#BackgroundFill).
//
// Based on techniques from RainbowTaskbar (MIT) and TranslucentTB (GPL).
// This implementation is original code for w11-theming-suite.
#pragma once

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <ocidl.h>     // IObjectWithSite
#include <unknwn.h>     // IClassFactory
#include <xamlOM.h>     // IVisualTreeService3, IXamlDiagnostics, IVisualTreeServiceCallback2
#include <oleauto.h>    // SysAllocString, SysFreeString
#include <atomic>

// Forward declarations
class TaskbarTAPSite;
class VisualTreeWatcher;

// ── Global state ──
extern HMODULE g_hModule;
extern std::atomic<long> g_refCount;
extern IVisualTreeService3* g_pTreeService;
extern IXamlDiagnostics* g_pDiagnostics;

// Appearance modes
enum TaskbarAppearance {
    APPEARANCE_DEFAULT = 0,
    APPEARANCE_TRANSPARENT = 1,
    APPEARANCE_ACRYLIC = 2
};

extern TaskbarAppearance g_appearance;

// ── Exported C functions (called from PowerShell via P/Invoke) ──
extern "C" {
    __declspec(dllexport) HRESULT __stdcall SetTaskbarTransparent();
    __declspec(dllexport) HRESULT __stdcall SetTaskbarAcrylic();
    __declspec(dllexport) HRESULT __stdcall SetTaskbarDefault();
    __declspec(dllexport) int __stdcall GetTaskbarTAPVersion();
}

// ── COM class: TAPSite — receives XAML diagnostics site ──
class TaskbarTAPSite : public IObjectWithSite {
public:
    TaskbarTAPSite();
    virtual ~TaskbarTAPSite();

    // IUnknown
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override;
    ULONG STDMETHODCALLTYPE AddRef() override;
    ULONG STDMETHODCALLTYPE Release() override;

    // IObjectWithSite
    HRESULT STDMETHODCALLTYPE SetSite(IUnknown* pUnkSite) override;
    HRESULT STDMETHODCALLTYPE GetSite(REFIID riid, void** ppvSite) override;

private:
    long m_refCount;
    IUnknown* m_pSite;
};

// ── COM class: VisualTreeWatcher — watches XAML tree changes ──
class VisualTreeWatcher : public IVisualTreeServiceCallback2 {
public:
    VisualTreeWatcher(IXamlDiagnostics* pDiag, IVisualTreeService3* pService);
    virtual ~VisualTreeWatcher();

    // IUnknown
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override;
    ULONG STDMETHODCALLTYPE AddRef() override;
    ULONG STDMETHODCALLTYPE Release() override;

    // IVisualTreeServiceCallback
    HRESULT STDMETHODCALLTYPE OnVisualTreeChange(
        ParentChildRelation relation,
        VisualElement element,
        VisualMutationType mutationType) override;

    // IVisualTreeServiceCallback2
    HRESULT STDMETHODCALLTYPE OnElementStateChanged(
        InstanceHandle element,
        VisualElementState elementState,
        LPCWSTR context) override;

    // Apply current appearance to tracked taskbar elements
    void ApplyAppearance(TaskbarAppearance appearance);

private:
    // Set Fill/Opacity on a Rectangle via GetIInspectableFromHandle + GetPropertyValuesChain
    void ApplyToRectangle(InstanceHandle handle, TaskbarAppearance appearance, bool isStroke);
    void SetRectangleOpacity(IInspectable* pElement, double opacity);
    long m_refCount;
    IXamlDiagnostics* m_pDiag;
    IVisualTreeService3* m_pService;

    // Tracked XAML element handles
    static const int MAX_TASKBARS = 8;
    struct TaskbarInfo {
        InstanceHandle backgroundFill;   // Rectangle#BackgroundFill
        InstanceHandle backgroundStroke; // Rectangle#BackgroundStroke
        InstanceHandle taskbarFrame;     // Taskbar.TaskbarFrame
        bool active;
    };
    TaskbarInfo m_taskbars[MAX_TASKBARS];
    int m_taskbarCount;

    // Helper: find parent with given type name
    InstanceHandle FindParentByType(InstanceHandle child, LPCWSTR typeName);
};

// ── COM class factory ──
class TaskbarTAPFactory : public IClassFactory {
public:
    TaskbarTAPFactory();

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override;
    ULONG STDMETHODCALLTYPE AddRef() override;
    ULONG STDMETHODCALLTYPE Release() override;

    HRESULT STDMETHODCALLTYPE CreateInstance(IUnknown* pOuter, REFIID riid, void** ppv) override;
    HRESULT STDMETHODCALLTYPE LockServer(BOOL fLock) override;

private:
    long m_refCount;
};