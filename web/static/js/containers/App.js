import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import Header from '../components/Header'
import Footer from '../components/Footer'

const App = ({children, tabs, body}) => {
  console.log(tabs)
  return (
    <div className="wrapper">
      <Header tabs={tabs}/>
      {body || children}
      <Footer />
    </div>
  );
}

export default connect()(App)

