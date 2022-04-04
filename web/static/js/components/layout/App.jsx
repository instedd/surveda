import React, { Component, PropTypes } from "react"
import HeaderContainer from "./HeaderContainer"
import Footer from "./Footer"
import { config } from "../../config"
import { IntlProvider } from "react-intl"
import { I18nextProvider } from "react-i18next"
import i18n from "../../i18next"
import Intercom from "react-intercom"
import I18nStyle from "../../i18nStyle"

class App extends Component {
  render() {
    const { children, tabs, body } = this.props

    return (
      <I18nextProvider i18n={i18n}>
        <IntlProvider locale="en-US">
          <div className="wrapper">
            <I18nStyle />
            <HeaderContainer tabs={tabs} logout={() => this.logout()} user={config.user} />
            <main>
              {body || children}
              <Footer />
              {config.intercom_app_id ? (
                <Intercom
                  appID={config.intercom_app_id}
                  user_id={config.user}
                  email={config.user}
                  name={config.user}
                />
              ) : null}
            </main>
            <form ref="logoutForm" method="post" action="/sessions">
              <input type="hidden" name="_csrf_token" value={config.csrf_token} />
              <input type="hidden" name="_method" value="DELETE" />
            </form>
          </div>
        </IntlProvider>
      </I18nextProvider>
    )
  }

  logout() {
    if (window.Intercom != null) {
      window.Intercom("shutdown")
    }
    this.refs.logoutForm.submit()
  }
}

App.propTypes = {
  children: PropTypes.node,
  tabs: PropTypes.node,
  body: PropTypes.node,
}

export default App
