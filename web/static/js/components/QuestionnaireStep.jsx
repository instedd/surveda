import React, { PropTypes } from 'react'

const QuestionnaireStep = ({ step }) => (
  <div>
    {step.title}
  </div>
)

QuestionnaireStep.propTypes = {
  step: PropTypes.object.isRequired,
}

export default QuestionnaireStep
