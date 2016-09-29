import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/questionnaireEditor'

class QuestionnaireClosedStep extends Component {
  selectStep(step) {
    const { dispatch } = this.props
    dispatch(actions.selectStep(step.id))
  }

  render() {
    const { step } = this.props

    return (
      <a href="#!" onClick={(event) => {
          this.selectStep(step)
          event.preventDefault()
        }} className="collection-item">
        {step.title}
      </a>
    )
  }
}

QuestionnaireClosedStep.propTypes = {
  step: PropTypes.object.isRequired,
}

export default connect()(QuestionnaireClosedStep);
