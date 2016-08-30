import React, { PropTypes } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

const ProjectForm = ({ onSubmit, project }) => {
  let input
  return (
    <div>
      <div>
        <label>Project Name</label>
        <div>
          <input type="text" placeholder="Project name" defaultValue={project.name} ref={ node => { input = node }
          }/>
        </div>
      </div>
      <br/>
      <div>
        <button type="button" onClick={() =>
          onSubmit(merge({}, project, {name: input.value}))
        }>
          Submit
        </button>
        <Link to='/projects'> Back</Link>
      </div>
    </div>
  )
}

ProjectForm.propTypes = {
  onSubmit: PropTypes.func.isRequired,
  project: PropTypes.object.isRequired
}

export default ProjectForm
