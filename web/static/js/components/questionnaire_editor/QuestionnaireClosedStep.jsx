import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaireEditor'
import UntitledIfEmpty from '../UntitledIfEmpty'

class QuestionnaireClosedStep extends Component {
  selectStep(event, step) {
    event.preventDefault()

    const { dispatch } = this.props
    dispatch(actions.selectStep(step.id))
  }

  render() {
    const { step, index } = this.props

    return (
      <a href="#!" className="truncate" onClick={(event) => this.selectStep(event, step)}>
        <UntitledIfEmpty text={step.title} emptyText='Untitled question' />
        <i className='material-icons right grey-text'>expand_more</i>
      </a>
    )
  }
}

QuestionnaireClosedStep.propTypes = {
  step: PropTypes.object.isRequired
}

export default connect()(QuestionnaireClosedStep)
