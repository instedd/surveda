import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaireEditor'
import { UntitledIfEmpty } from '../ui'

class QuestionnaireClosedStep extends Component {
  selectStep(event, step) {
    event.preventDefault()
    this.props.actions.selectStep(step.id)
  }

  render() {
    const { step } = this.props
    return (
      <a href='#!' className='truncate' onClick={(event) => this.selectStep(event, step)}>
        <UntitledIfEmpty text={step.title} emptyText='Untitled question' />
        <i className='material-icons right grey-text'>expand_more</i>
      </a>
    )
  }
}

QuestionnaireClosedStep.propTypes = {
  actions: PropTypes.object.isRequired,
  step: PropTypes.object.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(null, mapDispatchToProps)(QuestionnaireClosedStep)
