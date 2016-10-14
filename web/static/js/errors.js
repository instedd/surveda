import Raven from 'raven-js'
import { config } from './config'
import { Unauthorized } from './api'

Raven.config(config.sentryDsn).install()

window.addEventListener('unhandledrejection', (e) => {
  if (e.reason instanceof Unauthorized) {
    window.location = '/'
    // Ignore unauthorized errors
    return
  }

  onError(e)
  if (e.reason instanceof Error) {
    Raven.captureException(e.reason)
  } else {
    Raven.captureMessage('Unhandled promise rejection', {extra: {reason: e.reason}})
  }
})

window.addEventListener('error', (e) => {
  onError(e)
})

const onError = (e) => {
  event.preventDefault()
  console.log(event)
  $('#unhandledError').openModal()
}

