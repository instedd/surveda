import queryString from 'query-string'

class GuissoSession {
  constructor(config) {
    this.config = config
  }

  isPopupOpen() {
    return this.popup && !this.popup.closed
  }

  showPopup(url) {
    if (this.popup) {
      this.popup.location = url
    } else {
      this.popup = window.open(url, "_blank", "chrome=yes,centerscreen=yes,width=600,height=400")
      window.the_guisso_popup = this.popup
    }
    return this.popup
  }

  close() {
    if (this.popup) {
      this.popup.close()
      this.popup = null
    }
  }

  authorize(responseType, provider = null) {
    return new Promise((resolve, reject) => {
      const authorizeUrl = this.config.baseUrl + "/oauth2/authorize" +
        "?client_id=" + this.config.clientId +
        "&scope=" + escape("app=" + this.config.appId) +
        "&state=" + provider +
        "&response_type=" + responseType +
        "&redirect_uri=" + escape(window.location.origin + "/oauth_helper")

      const popup = this.showPopup(authorizeUrl)
      const listener = function(event) {
        if (event.source == popup) {
          window.removeEventListener("message", listener)
          const token = queryString.parse(event.data)
          resolve(token)
        }
      }
      window.addEventListener("message", listener, false)
    })
  }
}

export const newSession = (config) => new GuissoSession(config)
