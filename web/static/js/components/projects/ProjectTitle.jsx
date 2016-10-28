import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import merge from 'lodash/merge'
import * as projectActions from '../../actions/project'
import { updateProject } from '../../api'

class ProjectTitle extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    projectId: PropTypes.string.isRequired,
    project: PropTypes.object
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

  render() {
    const { project } = this.props
    if (project == null) return null

    return <EditableTitleLabel title={project.name} onSubmit={(value) => { this.handleSubmit(value) }} />
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    project: state.project.data
  }
}

export default withRouter(connect(mapStateToProps)(ProjectTitle))
