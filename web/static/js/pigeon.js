export const loadPigeonScript = (nuntiumBaseUrl) => {
  if (typeof window.pigeon != typeof undefined) {
    return Promise.resolve()
  }

  return new Promise((resolve, reject) => {
    const script = document.createElement('script')
    script.src = nuntiumBaseUrl + '/assets/pigeonui.js'
    script.async = 1
    script.onload = () => {
      resolve()
    }

    document.body.appendChild(script)
  })
}

export const addChannel = (accessToken) =>
  new Promise((resolve, reject) => {
    const callback = (channel) => resolve(channel)
    window.pigeon.addChannel({ callback: callback, accessToken: accessToken })
  })
