import React from 'react'
import Header from '../components/Header'
import Footer from '../components/Footer'
import { logout } from '../api'
import { config } from '../config'

export default ({ children, tabs, body }) => (
  <div className="wrapper">
    <Header tabs={tabs} logout={logout} user={config.user}/>
    <main>
      {body || children}
    </main>
    <Footer />
  </div>
)
