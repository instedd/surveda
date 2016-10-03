import React from 'react'
import Header from '../components/Header'
import Footer from '../components/Footer'
import { ConfirmationModal } from '../components/ConfirmationModal'
import { logout } from '../api'
import { config } from '../config'

export default ({ children, tabs, body }) => (
  <div className="wrapper">
    <Header tabs={tabs} logout={logout} user={config.user}/>
    <main>
      {body || children}
    </main>
    <Footer />
    <ConfirmationModal modalId="unhandledError" modalText="Please go to the site's index" header="Sorry, something went wrong" confirmationText="Go to index" onConfirm={(event) => onConfirm(event)}/>
  </div>
)

window.addEventListener('unhandledrejection', () => {
  onError()
});

window.addEventListener('error', () => {
  onError()
});

const onError = () => {
  event.preventDefault()
  $('#unhandledError').openModal();
}

const onConfirm = (event) => {
  event.preventDefault()
  window.location.href = baseUrl()
}

const baseUrl = () => {
  return window.location.protocol + "//" + window.location.host
}
