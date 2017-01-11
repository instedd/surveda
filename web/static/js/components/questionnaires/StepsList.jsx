import React, { PropTypes, Component } from 'react'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'

class StepsList extends Component {
  render() {
    const { steps, onClick, readOnly } = this.props
    if (steps.length != 0) {
      return (
        <ul className='collapsible'>
          { steps.map((step) => (
            <li key={step.id}>
              <QuestionnaireClosedStep
                step={step}
                onClick={stepId => onClick(stepId)}
                readOnly={readOnly}
              />
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
  readOnly: PropTypes.bool
}

export default StepsList
