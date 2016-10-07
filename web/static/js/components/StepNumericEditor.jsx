import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

class StepNumericEditor extends Component {
  render () {
    const { step } = this.props
    return <div>Numeric step</div>
  }
}

StepNumericEditor.propTypes = {
  step: PropTypes.object.isRequired
}

export default connect()(StepNumericEditor)
