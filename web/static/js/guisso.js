import queryString from 'query-string';

export const obtainToken = (guissoConfig) =>
  new Promise((resolve, reject) => {
    var authorizeUrl = guissoConfig.baseUrl + "/oauth2/authorize" +
      "?client_id=" + guissoConfig.clientId +
      "&scope=" + escape("app=" + guissoConfig.appId) +
      "&response_type=token" +
      "&redirect_uri=" + escape(window.location.origin + "/oauth_helper")

    var popup = window.open(authorizeUrl, "_blank", "chrome=yes,centerscreen=yes,width=600,height=400");
    const listener = function(event) {
      if (event.source == popup) {
        window.removeEventListener("message", listener);
        popup.close();
        const token = queryString.parse(event.data);
        resolve(token);
      }
    }
    window.addEventListener("message", listener, false)
  });
