import React, { PropTypes, Component } from 'react'
import merge from 'lodash/merge'
import { Link } from 'react-router'

class ProjectForm extends Component {
  propTypes = {
    onSubmit: PropTypes.func.isRequired,
    project: PropTypes.object
  }

  render() {
    const { onSubmit, project } = this.props

    if (!project) {
      return <div>Loading...</div>
    }

    return (
      <div>
        <div>
          <label>Project Name</label>
          <div>
            <input type="text" placeholder="Project name" defaultValue={project.name} ref="input"/>
          </div>
        </div>
        <br/>
        <div>
          <button type="button" onClick={() =>
            onSubmit(merge({}, project, { name: this.refs.input.value }))
          }>
            Submit
          </button>
          <Link to='/projects'> Back</Link>
        </div>
      </div>
    )
  }
}

export default ProjectForm
