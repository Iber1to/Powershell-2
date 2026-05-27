import msal


def get_client_credential():
    return {
        'client_id': "11111111-1111-1111-1111-000000008765",
        'client_secret': "REDACTED_CLIENT_SECRET",
        'authority': "https://login.microsoftonline.com/11111111-1111-1111-1111-000000008766",
        'scope': ['https://graph.microsoft.com/.default']
    }
def get_access_token():
    credentials = get_client_credential()
    app = msal.ConfidentialClientApplication(
        credentials['client_id'], authority=credentials['authority'],
        client_credential=credentials['client_secret']
    )

    result = app.acquire_token_silent(credentials['scope'], account=None)
    if not result:
        result = app.acquire_token_for_client(scopes=credentials['scope'])
    
    return result['access_token'] if 'access_token' in result else None