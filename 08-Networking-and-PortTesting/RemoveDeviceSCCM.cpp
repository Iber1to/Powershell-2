#include "pch.h"
#define _WIN32_DCOM
#define UNICODE
#include <iostream>
using namespace std;
#include <comdef.h>
#include <Wbemidl.h>
#pragma comment(lib, "wbemuuid.lib")
#pragma comment(lib, "credui.lib")
#pragma comment(lib, "comsuppw.lib")
#include <wincred.h>
#include <strsafe.h>

extern "C" __declspec(dllexport) int ExecuteWMIQuery(
    const wchar_t* UUID,
    const wchar_t* UserCredential,
    const wchar_t* PasswordCredential,
    const wchar_t* RemoteServer,
    const wchar_t* RemoteSite)
{
    HRESULT hres;

    // Paso 1: Inicializar COM.
    hres = CoInitializeEx(0, COINIT_MULTITHREADED);
    if (FAILED(hres))
    {
        cout << "Fallo al inicializar la biblioteca COM. Código de error = 0x"
            << hex << hres << endl;
        return hres; // El programa ha fallado.
    }

    // Paso 2: Establecer niveles de seguridad COM generales.
    hres = CoInitializeSecurity(
        NULL, -1, NULL, NULL, RPC_C_AUTHN_LEVEL_DEFAULT,
        RPC_C_IMP_LEVEL_IDENTIFY, NULL, EOAC_NONE, NULL);

    if (FAILED(hres))
    {
        cout << "Fallo al inicializar seguridad. Código de error = 0x"
            << hex << hres << endl;
        CoUninitialize();
        return hres; // El programa ha fallado.
    }

    // Paso 3: Obtener el localizador inicial para WMI.
    IWbemLocator* pLoc = NULL;
    hres = CoCreateInstance(
        CLSID_WbemLocator, 0, CLSCTX_INPROC_SERVER, IID_IWbemLocator, (LPVOID*)&pLoc);

    if (FAILED(hres))
    {
        cout << "Fallo al crear objeto IWbemLocator. Código de error = 0x"
            << hex << hres << endl;
        CoUninitialize();
        return hres; // El programa ha fallado.
    }

    // Paso 4: Conectar a WMI a través del método IWbemLocator::ConnectServer.
    IWbemServices* pSvc = NULL;
    bool useNTLM = true;
    bool useToken = false;
    wchar_t pszName[CREDUI_MAX_USERNAME_LENGTH + 1] = { 0 };
    wchar_t pszPwd[CREDUI_MAX_PASSWORD_LENGTH + 1] = { 0 };
    wchar_t pszDomain[CREDUI_MAX_USERNAME_LENGTH + 1];
    wchar_t pszUserName[CREDUI_MAX_USERNAME_LENGTH + 1];
    wchar_t pszAuthority[CREDUI_MAX_USERNAME_LENGTH + 1];

    wcsncpy_s(pszName, UserCredential, CREDUI_MAX_USERNAME_LENGTH);
    wcsncpy_s(pszPwd, PasswordCredential, CREDUI_MAX_PASSWORD_LENGTH);

    if (!useNTLM)
    {
        StringCchPrintf(pszAuthority, CREDUI_MAX_USERNAME_LENGTH + 1, L"kERBEROS:%s", RemoteServer);
    }

    std::wstring combinedPath = L"\\\\" + std::wstring(RemoteServer) + L"\\root\\SMS\\site_" + std::wstring(RemoteSite);
    hres = pLoc->ConnectServer(
        _bstr_t(combinedPath.c_str()), _bstr_t(useToken ? NULL : pszName), _bstr_t(useToken ? NULL : pszPwd),
        NULL, NULL, _bstr_t(useNTLM ? NULL : pszAuthority), NULL, &pSvc);

    if (FAILED(hres))
    {
        cout << "No se pudo conectar. Código de error = 0x"
            << hex << hres << endl;
        pLoc->Release();
        CoUninitialize();
        return hres; // El programa ha fallado.
    }

    // Paso 5: Crear COAUTHIDENTITY que se puede usar para establecer seguridad en el proxy.
    COAUTHIDENTITY* userAcct = NULL;
    COAUTHIDENTITY authIdent;
#define ERROR_NO_DOMAIN_SPECIFIED 0x80001000
    if (!useToken)
    {
        memset(&authIdent, 0, sizeof(COAUTHIDENTITY));
        authIdent.PasswordLength = wcslen(pszPwd);
        authIdent.Password = (USHORT*)pszPwd;
        LPWSTR slash = wcschr(pszName, L'\\');
        if (slash == NULL)
        {
            cout << "No se pudo crear la identidad de autenticación. No se especificó dominio.\n";
            pSvc->Release();
            pLoc->Release();
            CoUninitialize();
            return ERROR_NO_DOMAIN_SPECIFIED; // El programa ha fallado.
        }

        StringCchCopy(pszUserName, CREDUI_MAX_USERNAME_LENGTH + 1, slash + 1);
        authIdent.User = (USHORT*)pszUserName;
        authIdent.UserLength = wcslen(pszUserName);
        StringCchCopyN(pszDomain, CREDUI_MAX_USERNAME_LENGTH + 1, pszName, slash - pszName);
        authIdent.Domain = (USHORT*)pszDomain;
        authIdent.DomainLength = slash - pszName;
        authIdent.Flags = SEC_WINNT_AUTH_IDENTITY_UNICODE;
        userAcct = &authIdent;
    }

    // Paso 6: Establecer niveles de seguridad en una conexión WMI.
    hres = CoSetProxyBlanket(pSvc, RPC_C_AUTHN_DEFAULT, RPC_C_AUTHZ_DEFAULT, COLE_DEFAULT_PRINCIPAL,
        RPC_C_AUTHN_LEVEL_PKT_PRIVACY, RPC_C_IMP_LEVEL_IMPERSONATE, userAcct, EOAC_NONE);

    if (FAILED(hres))
    {
        cout << "No se pudo establecer el proxy blanket. Código de error = 0x"
            << hex << hres << endl;
        pSvc->Release();
        pLoc->Release();
        CoUninitialize();
        return hres; // El programa ha fallado.
    }

    // Paso 7: Utilizar el puntero IWbemServices para hacer solicitudes de WMI.
    IEnumWbemClassObject* pEnumerator = NULL;
    std::wstring query = L"select * from SMS_R_System where SMS_R_System.SMBIOSGUID='" + std::wstring(UUID) + L"'";
    hres = pSvc->ExecQuery(bstr_t("WQL"), bstr_t(query.c_str()), WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY, NULL, &pEnumerator);

    if (FAILED(hres))
    {
        cout << "La consulta falló. Código de error = 0x"
            << hex << hres << endl;
        pSvc->Release();
        pLoc->Release();
        CoUninitialize();
        return hres; // El programa ha fallado.
    }

    // Paso 8: Asegurar el proxy del enumerador.
    hres = CoSetProxyBlanket(pEnumerator, RPC_C_AUTHN_DEFAULT, RPC_C_AUTHZ_DEFAULT, COLE_DEFAULT_PRINCIPAL,
        RPC_C_AUTHN_LEVEL_PKT_PRIVACY, RPC_C_IMP_LEVEL_IMPERSONATE, userAcct, EOAC_NONE);

    if (FAILED(hres))
    {
        cout << "No se pudo establecer el proxy blanket en el enumerador. Código de error = 0x"
            << hex << hres << endl;
        pEnumerator->Release();
        pSvc->Release();
        pLoc->Release();
        CoUninitialize();
        return hres; // El programa ha fallado.
    }

    // Borrar credenciales de la memoria.
    SecureZeroMemory(pszName, sizeof(pszName));
    SecureZeroMemory(pszPwd, sizeof(pszPwd));
    SecureZeroMemory(pszUserName, sizeof(pszUserName));
    SecureZeroMemory(pszDomain, sizeof(pszDomain));

    // Paso 9: Obtener los datos de la consulta en el paso 7.
    IWbemClassObject* pclsObj = NULL;
    ULONG uReturn = 0;

    while (pEnumerator)
    {
        HRESULT hr = pEnumerator->Next(WBEM_INFINITE, 1, &pclsObj, &uReturn);

        if (0 == uReturn)
        {
            break;
        }

        VARIANT vtObjectPath;
        hr = pclsObj->Get(L"__PATH", 0, &vtObjectPath, NULL, NULL);
        if (SUCCEEDED(hr) && vtObjectPath.vt == VT_BSTR)
        {
            hr = pSvc->DeleteInstance(vtObjectPath.bstrVal, 0, NULL, NULL);
            if (FAILED(hr))
            {
                wcout << L"Error al eliminar el objeto: " << vtObjectPath.bstrVal << endl;
            }
            VariantClear(&vtObjectPath);
        }
        else
        {
            wcout << L"No se pudo obtener el path del objeto para eliminarlo." << endl;
        }

        pclsObj->Release();
        pclsObj = NULL;
    }


    // Limpieza
    pSvc->Release();
    pLoc->Release();
    pEnumerator->Release();
    if (pclsObj)
    {
        pclsObj->Release();
    }
    CoUninitialize();
    return 0; // El programa se completó con éxito.
}

/*
Codigos de error:
    - Codigo de error = 0x80070005 --> Usuario o contraseña incorrectos
    - Codigo de error = 0x80041003 ---> Usuario no tiene permisos para conectar a WMI / o no tiene autorizacion en la configuracion DCOM
    - Codigo de error = 0x800706ba --> Problema con la conectividad contra el servidor remoto.
    - Codigo de error = 0x8004100e --> El parametro Site no es valido en el servidor remoto.
*/