import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import Project from './Project'
import Header from '../components/Header'
import Footer from '../components/Footer'

const App = ({children}) => {
  return (
    <div className="container-fluid">
      <Header />
      {children}
      <Footer />
    </div>
  );
}

export default connect()(App)

