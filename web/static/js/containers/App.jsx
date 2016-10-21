import React, { PropTypes } from 'react'
import HeaderContainer from './HeaderContainer'
import Footer from '../components/Footer'
import ConfirmationModal from '../components/ConfirmationModal'
import { logout } from '../api'
import { config } from '../config'

const App = ({ children, tabs, body }) => (
  <div className='wrapper'>
    <HeaderContainer tabs={tabs} logout={logout} user={config.user} />
    <main>
      {body || children}
    </main>
    <Footer />
    <ConfirmationModal modalId='unhandledError' modalText='Please go to the home page' header='Sorry, something went wrong' confirmationText='Click to go to the home page' onConfirm={(event) => onConfirm(event)} />
  </div>
)

App.propTypes = {
  children: PropTypes.node,
  tabs: PropTypes.node,
  body: PropTypes.node
}

const onConfirm = (event) => {
  event.preventDefault()
  window.location.href = '/'
}

export default App
