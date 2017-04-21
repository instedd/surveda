import React, { PropTypes, Component } from 'react'
import QuestionnaireClosedStep from './QuestionnaireClosedStep'

class StepsList extends Component {
  render() {
    const { steps, errorPath, onClick, readOnly } = this.props
    if (steps.length != 0) {
      return (
        <ul className='collapsible'>
          { steps.map((step, index) => (
            <li key={step.id}>
              <QuestionnaireClosedStep
                step={step}
                stepIndex={index}
                errorPath={`${errorPath}[${index}]`}
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
  errorPath: PropTypes.string,
  onClick: PropTypes.func,
  readOnly: PropTypes.bool
}

export default StepsList
