# ms_auth.py

Helper de **autenticación contra Microsoft Graph con MSAL** (client credentials) reutilizado por los proyectos de Python.

## Cómo funciona
`get_client_credential()` devuelve client_id, client_secret, authority (tenant) y scope; `get_access_token()` crea una `ConfidentialClientApplication` de MSAL y obtiene el token de aplicación.

## Tecnología
MSAL · OAuth2 client credentials · Microsoft Graph.

## Notas
El `client_secret` y los IDs se han redactado. `ms_auth_2.py` es el helper equivalente (casi vacío) de otro de los proyectos.
