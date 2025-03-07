# `fronend/`

1. Files and Folder

    - `templates/config.json`
      > Configuration file for the Dependency-Track Front End (UI)

      ```json
      {
        // Required
        // The base URL of the API server.
        // NOTE:
        //   * This URL must be reachable by the browsers of your users.
        //   * The frontend container itself does NOT communicate with the API server directly, it just serves static files.
        //   * When deploying to dedicated servers, please use the external IP or domain of the API server.
        "API_BASE_URL": "",       
        "API_WITH_CREDENTIALS": null,
        // Optional
        // Defines the issuer URL to be used for OpenID Connect.
        // See alpine.oidc.issuer property of the API server.
        "OIDC_ISSUER": null,
        // Optional
        // Defines the client ID for OpenID Connect.
        "OIDC_CLIENT_ID": null,
        // Optional
        // Defines the scopes to request for OpenID Connect.
        // See also: https://openid.net/specs/openid-connect-basic-1_0.html#Scopes
        "OIDC_SCOPE": "openid profile email",
        // Optional
        // Specifies the OpenID Connect flow to use.
        // Values other than "implicit" will result in the Code+PKCE flow to be used.
        // Usage of the implicit flow is strongly discouraged, but may be necessary when
        // the IdP of choice does not support the Code+PKCE flow.
        // See also:
        //   - https://oauth.net/2/grant-types/implicit/
        //   - https://oauth.net/2/pkce/
        "OIDC_FLOW": null,
        // Optional
        // Defines the text of the OpenID Connect login button. 
        "OIDC_LOGIN_BUTTON_TEXT": null
      }
      ```
