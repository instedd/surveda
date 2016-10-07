import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

class StepMultipleChoiceEditor extends Component {
  render () {
    const { step } = this.props
    return <div>Multiple choice step</div>
  }
}

StepMultipleChoiceEditor.propTypes = {
  step: PropTypes.object.isRequired
}

export default connect()(StepMultipleChoiceEditor)
