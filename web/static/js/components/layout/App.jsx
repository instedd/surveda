import React, { Component, PropTypes } from 'react'
import HeaderContainer from './HeaderContainer'
import Footer from './Footer'
import { config } from '../../config'
import { IntlProvider } from 'react-intl'

class App extends Component {
  render() {
    const { children, tabs, body } = this.props

    return (
      <IntlProvider locale='en-US'>
        <div className='wrapper'>
          <HeaderContainer tabs={tabs} logout={() => this.logout()} user={config.user} />
          <main>
            {body || children}
            <Footer />
          </main>
          <form ref='logoutForm' method='post' action='/sessions'>
            <input type='hidden' name='_csrf_token' value={config.csrf_token} />
            <input type='hidden' name='_method' value='DELETE' />
          </form>
        </div>
      </IntlProvider>
    )
  }

  logout() {
    this.refs.logoutForm.submit()
  }
}

App.propTypes = {
  children: PropTypes.node,
  tabs: PropTypes.node,
  body: PropTypes.node
}

export default App
