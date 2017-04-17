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
      this.popup = window.open(url, '_blank', 'chrome=yes,centerscreen=yes,width=600,height=400')
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

  authorize(responseType, provider = null, baseUrl = null) {
    return new Promise((resolve, reject) => {
      const state = (provider && baseUrl ? `${provider}|${baseUrl}` : null)
      const authorizeUrl = this.config.baseUrl + '/oauth2/authorize' +
        '?client_id=' + this.config.clientId +
        '&scope=' + encodeURIComponent('app=' + this.config.appId) +
        '&state=' + state +
        '&response_type=' + responseType +
        '&redirect_uri=' + encodeURIComponent(window.location.origin + '/oauth_client/callback')

      const popup = this.showPopup(authorizeUrl)
      const watchdog = window.setInterval(() => {
        if (popup.closed) {
          reject()
        }
      }, 100)
      const listener = function(event) {
        if (event.source == popup) {
          window.removeEventListener('message', listener)
          window.clearInterval(watchdog)
          if (event.data.error && event.data.error.length > 0) {
            console.log(event.data)
            reject(event.data.error)
          } else {
            const token = queryString.parse(event.data)
            resolve(token)
          }
        }
      }
      window.addEventListener('message', listener, false)
    })
  }
}

export const newSession = (config) => new GuissoSession(config)
