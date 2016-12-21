import React, { PropTypes, Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'

class StepsList extends Component {
  onMoveStep(sourceStepId, targetStepId) {
    this.props.questionnaireActions.moveStep(sourceStepId, targetStepId)
  }

  render() {
    const { steps, onClick } = this.props
    if (steps.length != 0) {
      return (
        <ul className='collapsible'>
          { steps.map((step) => (
            <li key={step.id}>
              <QuestionnaireClosedStep
                step={step}
                onClick={stepId => onClick(stepId)}
                onMoveUnderStep={(sourceStepId, targetStepId) => this.onMoveStep(sourceStepId, targetStepId)}
                draggable={step.type != 'language-selection'} />
            </li>
          ))}
        </ul>
      )
    } else {
      return null
    }
  }
}

StepsList.propTypes = {
  steps: PropTypes.array,
  onClick: PropTypes.func,
  questionnaireActions: PropTypes.object
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(null, mapDispatchToProps)(StepsList)
