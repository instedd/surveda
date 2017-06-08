import React, { PropTypes } from 'react'
import HeaderContainer from './HeaderContainer'
import Footer from './Footer'
import { logout } from '../../api'
import { config } from '../../config'
import { IntlProvider } from 'react-intl'

const App = ({ children, tabs, body }) => (
  <IntlProvider locale='en-US'>
    <div className='wrapper'>
      <HeaderContainer tabs={tabs} logout={logout} user={config.user} />
      <main>
        {body || children}
        <Footer />
      </main>
    </div>
  </IntlProvider>
)

App.propTypes = {
  children: PropTypes.node,
  tabs: PropTypes.node,
  body: PropTypes.node
}

export default App
