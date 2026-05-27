# Arquitectura de acceso restringido a SharePoint Online para proveedor externo  


## 1. Objetivo

Permitir que un proveedor externo acceda **en modo solo lectura** a un único sitio de SharePoint Online de la organización (`<SITE_URL>`), evitando conceder permisos globales sobre todo el tenant de SharePoint.

La solución se basa en:

- Uso del permiso Microsoft Graph `Sites.Selected` en la aplicación del proveedor.
- Uso de una segunda aplicación interna con permisos elevados (`Sites.FullControl.All`) que actúa solo como **herramienta de administración** para delegar permisos sobre el sitio concreto.
- Aplicación estricta del principio de mínimo privilegio.

---

## 2. Alcance

Incluye:

- Acceso del proveedor a ficheros y carpetas del sitio `<SITE_URL>`, solo lectura.
- Configuración de aplicaciones Azure AD con autenticación `client_credentials`.
- Delegación granular de permisos sobre un `siteId` concreto.
- Validación de accesos vía Microsoft Graph.

No incluye:

- Permisos sobre otros sitios.
- Acceso por usuarios finales.
- Modelos de acceso global a todo el tenant.

---

## 3. Parámetros de configuración

### Tenant
- `<TENANT_ID>`

### Aplicación del proveedor
- `<PROVIDER_APP_NAME>`
- `<PROVIDER_APP_CLIENT_ID>`
- `<PROVIDER_APP_CLIENT_SECRET>`
- Permiso: `Sites.Selected`

### Aplicación interna para delegación
- `<DELEGATION_APP_NAME>`
- `<DELEGATION_APP_CLIENT_ID>`
- `<DELEGATION_APP_CERT_THUMBPRINT>`
- Permiso: `Sites.FullControl.All`

### Sitio SharePoint objetivo
- `<SITE_URL>`
- `<SITE_HOSTNAME>`
- `<SITE_PATH>`
- `<SITE_ID>` (calculado)

---

## 4. Componentes de la solución

### 4.1. Aplicación Azure AD para el proveedor
App entregada al proveedor que obtendrá un token y accederá solo al sitio autorizado.  
No tiene permisos globales; únicamente `Sites.Selected`.

### 4.2. Aplicación interna de delegación
App interna del cliente con `Sites.FullControl.All`, usada solo para:
- Calcular el `siteId`
- Asignar permisos a la app del proveedor

### 4.3. Sitio SharePoint
El sitio `<SITE_URL>` es el único sobre el que se otorgará acceso.

### 4.4. PowerShell / Microsoft Graph
Se utilizan para:
- Obtener tokens
- Calcular `siteId`
- Crear permisos
- Validar lectura del proveedor

---

## 5. Diseño de alto nivel

### Flujo

1. Se registran ambas apps en Azure AD.
2. Se configura certificado (app delegación) y secreto (app proveedor).
3. La app de delegación obtiene token y calcula `<SITE_ID>`.
4. Se asigna rol `read` a favor de `<PROVIDER_APP_CLIENT_ID>` sobre `<SITE_ID>`.
5. El proveedor obtiene token y accede al contenido del sitio.

### Delegación del rol

La app i
