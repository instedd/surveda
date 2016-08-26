import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const StudyForm = ({ onSubmit, study }) => {
  let input
  return (
    <div>
      <div>
        <label>Study Name</label>
        <div>
          <input type="text" placeholder="Study name" defaultValue={study.name} ref={ node => { input = node }
          }/>
        </div>
      </div>
      <div>
        <button type="button" onClick={() =>
          onSubmit(merge({}, study, {name: input.value}))
        }>
          Submit
        </button>
        <Link to='/studies'>Back</Link>
      </div>
    </div>
  )
}

StudyForm.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  study: PropTypes.object.isRequired
}

export default StudyForm
