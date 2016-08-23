import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import Study from './Study'

const App = () => {
  return (
    <div>
      <p>We are App!</p>
      <a href="/studies">studies</a>
    </div>
  );
}

export default connect()(App)

