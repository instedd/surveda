import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import Header from '../components/Header'
import Footer from '../components/Footer'

const App = ({children}) => {
  return (
    <div className="wrapper">
      <Header />
      {children}
      <Footer />
    </div>
  );
}

export default connect()(App)

