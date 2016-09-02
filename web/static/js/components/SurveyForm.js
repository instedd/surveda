import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const SurveyForm = ({ onSubmit, survey, children }) => {
  let input
  return (
    <div>
      <div className="col-md-4" style={{border: `1px solid black`, height: `400px`}}>
        <label>Progress bar</label>
        <div>
          Item 1
        </div>
        <div>
          Item 2
        </div>
        <div>
          Item 3
        </div>
        <div>
          Item 4
        </div>
        <div>
          Item 5
        </div>
      </div>
      <div className="col-md-8">
        {children}
      </div>
    </div>
  )
}

SurveyForm.propTypes = {
  // onSubmit: PropTypes.func.isRequired,
  survey: PropTypes.object.isRequired
}

export default SurveyForm
