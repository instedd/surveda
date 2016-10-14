import Raven from 'raven-js'
import { config } from './config'

Raven.config(config.sentryDsn, {release: config.version}).install()
Raven.setUserContext({email: config.user})

window.addEventListener('unhandledrejection', (e) => {
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

