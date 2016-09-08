import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import Header from '../components/Header'
import Footer from '../components/Footer'

const App = ({children, tabs, body}) => (
  <div className="wrapper">
    <Header tabs={tabs}/>
    <div className="content">
      {body || children}
    </div>
    <Footer />
  </div>
)

export default connect()(App)

