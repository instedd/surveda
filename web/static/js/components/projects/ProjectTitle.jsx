import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import merge from 'lodash/merge'
import * as projectActions from '../../actions/project'
import { updateProject } from '../../api'
import { toggleColourScheme } from '../../toggleColourScheme'

class ProjectTitle extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    projectId: PropTypes.any.isRequired,
    project: PropTypes.object,
    readOnly: PropTypes.bool
  }

  componentWillMount() {
    const { dispatch, projectId } = this.props
    dispatch(projectActions.fetchProject(projectId))
  }

  handleSubmit(newName) {
    const { dispatch, project } = this.props
    if (project.name == newName) return
    const newProject = merge({}, project, {name: newName})

    dispatch(projectActions.updateProject(newProject)) // Optimistic update
    updateProject(newProject)
      .then(response => dispatch(projectActions.updateProject(response.entities.projects[response.result])))
  }

  onClickToggle(colourScheme) {
    const {project} = this.props
    console.log(colourScheme)
    toggleColourScheme(project.colourScheme)
  }

  render() {
    const { project, readOnly } = this.props
    if (project == null) return null

    return (
      <div>
        <p onClick={() => this.onClickToggle()}>Set colour scheme</p>
        <input
          id={`default`}
          type='radio'
          name='toggleDefault'
          value='default'
          checked={project.colourScheme == 'default'}
          onChange={e => this.onClickToggle('default')}
          disabled={readOnly}
        />
        <EditableTitleLabel title={project.name} entityName='project' onSubmit={(value) => { this.handleSubmit(value) }} readOnly={readOnly} />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    project: state.project.data,
    readOnly: state.project && state.project.data ? state.project.data.readOnly : true
  }
}

export default withRouter(connect(mapStateToProps)(ProjectTitle))
