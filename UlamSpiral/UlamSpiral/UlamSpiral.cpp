// UlamSpiral.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include <uxtheme.h> // for buffered painting
#include "UlamSpiral.h"
#include "spiral.h"

#define MAX_LOADSTRING 100

// Global Variables:
HINSTANCE hInst;                                // current instance
WCHAR szTitle[MAX_LOADSTRING];                  // The title bar text
WCHAR szWindowClass[MAX_LOADSTRING];            // the main window class name

namespace
{
	int spiral_size;
	int spiral_start;
	int spiral_incr;
	std::valarray<int> primes_spiral;
	
	void generate_spiral ()
	{
		auto my_spiral = rwt::spiral::make_spiral (spiral_size, spiral_start, spiral_incr);
		primes_spiral = my_spiral.apply (rwt::spiral::is_prime);
	}
}

// Forward declarations of functions included in this code module:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    About(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    Settings(HWND, UINT, WPARAM, LPARAM);

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // TODO: Place code here.

    // Initialize global strings
    LoadStringW(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(hInstance, IDC_ULAMSPIRAL, szWindowClass, MAX_LOADSTRING);
    MyRegisterClass(hInstance);

	spiral_size = 20;
	spiral_start = 1;
	spiral_incr = 1;
	generate_spiral ();

    // Perform application initialization:
    if (!InitInstance (hInstance, nCmdShow))
    {
        return FALSE;
    }

    HACCEL hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_ULAMSPIRAL));

    MSG msg;

    // Main message loop:
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return (int) msg.wParam;
}



//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

	wcex.style          = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc    = WndProc;
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = hInstance;
    wcex.hIcon          = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_ULAMSPIRAL));
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
    wcex.lpszMenuName   = MAKEINTRESOURCEW(IDC_ULAMSPIRAL);
    wcex.lpszClassName  = szWindowClass;
    wcex.hIconSm        = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

    return RegisterClassExW(&wcex);
}

//
//   FUNCTION: InitInstance(HINSTANCE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   hInst = hInstance; // Store instance handle in our global variable

   HWND hWnd = CreateWindowW(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, nullptr, nullptr, hInstance, nullptr);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

//
//  FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE: Processes messages for the main window.
//
//  WM_COMMAND  - process the application menu
//  WM_PAINT    - Paint the main window
//  WM_DESTROY  - post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	static bool is_moving = false;

    switch (message)
    {
	case WM_CREATE:
		BufferedPaintInit ();
		break;
	case WM_ENTERSIZEMOVE:
		is_moving = true;
		break;
	case WM_EXITSIZEMOVE:
		is_moving = false;
		break;
    case WM_COMMAND:
        {
			INT_PTR result;
            int wmId = LOWORD(wParam);
            // Parse the menu selections:
            switch (wmId)
            {
			case ID_FILE_SETTINGS:
				result = DialogBox (hInst, MAKEINTRESOURCE (IDD_SETTINGSDLG), hWnd, Settings);
				if (result == IDOK)
				{
					generate_spiral ();
					InvalidateRect (hWnd, nullptr, true);
				}
				break;
            case IDM_ABOUT:
                DialogBox (hInst, MAKEINTRESOURCE (IDD_ABOUTBOX), hWnd, About);
                break;
            case IDM_EXIT:
                DestroyWindow(hWnd);
                break;
            default:
                return DefWindowProc(hWnd, message, wParam, lParam);
            }
        }
        break;
    case WM_PAINT:
        {
			if (is_moving) break;
			const int size = spiral_size;

			RECT rect;
            PAINTSTRUCT ps;
            HDC winHdc = BeginPaint(hWnd, &ps);
			GetClientRect (hWnd, &rect);

			// set up buffered drawing
			HDC hdc;
			BP_PAINTPARAMS params = { sizeof (params), BPPF_ERASE };
			HPAINTBUFFER hBufferedPaint =
			  BeginBufferedPaint (winHdc, &rect, BPBF_COMPATIBLEBITMAP,
									&params, &hdc);
			if (hBufferedPaint == nullptr)
			{
				EndPaint (hWnd, &ps);
				break;
			}
			int savedDC = SaveDC (hdc);

			// it seems we have to set the coordinate space again on the buffered HDC
			SetMapMode (hdc, MM_ANISOTROPIC);
			SetWindowExtEx (hdc, size, size, nullptr);
			SetViewportExtEx (hdc, rect.right - rect.left, rect.bottom - rect.top, nullptr);
			SetViewportOrgEx (hdc, 0, 0, nullptr);

			std::size_t idx = 0;
			for(int y = 0; y < size; ++y)
				for (int x = 0; x < size; ++x)
				{
					HBRUSH brush = GetSysColorBrush (primes_spiral[idx++] ? COLOR_HIGHLIGHT : COLOR_WINDOW);
					rect.top = y;
					rect.left = x;
					rect.bottom = rect.top + 1;
					rect.right = rect.left + 1;
					FillRect (hdc, &rect, brush);
				}

			RestoreDC (hdc, savedDC);
			EndBufferedPaint (hBufferedPaint, true);
            EndPaint(hWnd, &ps);
        }
        break;
	case WM_NCDESTROY:
		BufferedPaintUnInit ();
		break;
	case WM_DESTROY:
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

// Message handler for settings dialog.
INT_PTR CALLBACK Settings (HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER (lParam);
	
	wchar_t buff[20];

	switch (message)
	{
	case WM_INITDIALOG:
		swprintf (buff, 20, L"%d", spiral_size);
		SetDlgItemText (hDlg, IDC_EDITSZ, buff);
		swprintf (buff, 20, L"%d", spiral_start);
		SetDlgItemText (hDlg, IDC_EDITSTART, buff);
		swprintf (buff, 20, L"%d", spiral_incr);
		SetDlgItemText (hDlg, IDC_EDITINCR, buff);
		return (INT_PTR)TRUE;
	case WM_COMMAND:
	{
		auto cmd = LOWORD (wParam);
		if (cmd == IDOK)
		{
			int val = -1;
			GetDlgItemText (hDlg, IDC_EDITSZ, buff, 20);
			swscanf_s (buff, L"%d", &val);
			if (val > 0) spiral_size = val;
			val = -1;
			GetDlgItemText (hDlg, IDC_EDITSTART, buff, 20);
			swscanf_s (buff, L"%d", &val);
			if (val >= 0) spiral_start = val;
			val = -1;
			GetDlgItemText (hDlg, IDC_EDITINCR, buff, 20);
			swscanf_s (buff, L"%d", &val);
			if (val >= 0) spiral_incr = val;
		}
		if (cmd == IDOK || cmd == IDCANCEL)
		{
			EndDialog (hDlg, LOWORD (wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	}
	return (INT_PTR)FALSE;
}

// Message handler for about box.
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);
    switch (message)
    {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
        {
            EndDialog(hDlg, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}
