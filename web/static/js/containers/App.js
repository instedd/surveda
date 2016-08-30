import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import Project from './Project'

const App = () => {
  return (
    <div>
      <p>We are App!</p>
      <a href="/projects">projects</a>
    </div>
  );
}

export default connect()(App)

