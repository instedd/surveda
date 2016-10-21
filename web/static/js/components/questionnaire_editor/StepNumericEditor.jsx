import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

class StepNumericEditor extends Component {
  render() {
    return <div />
  }
}

StepNumericEditor.propTypes = {
  step: PropTypes.object.isRequired
}

export default connect()(StepNumericEditor)
