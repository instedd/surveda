import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaireEditor'

class QuestionnaireClosedStep extends Component {
  selectStep(event, step) {
    event.preventDefault()

    const { dispatch } = this.props
    dispatch(actions.selectStep(step.id))
  }

  render() {
    const { step, index } = this.props

    return (
      <a href="#!" onClick={(event) => this.selectStep(event, step)} className="collection-item">
        {step.title}
      </a>
    )
  }
}

QuestionnaireClosedStep.propTypes = {
  step: PropTypes.object.isRequired,
}

export default connect()(QuestionnaireClosedStep);
