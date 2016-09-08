import React, { Component, PropTypes } from 'react'
import { browserHistory } from 'react-router'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/projects'
import { updateProject } from '../api'
import ProjectForm from '../components/ProjectForm'

class EditProject extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    if (projectId) {
      dispatch(actions.fetchProject(projectId))
    }
  }

  handleSubmit(dispatch) {
    return (project) => {
      updateProject(project).then(project => dispatch(actions.updateProject(project))).then(() => browserHistory.push('/projects')).catch((e) => dispatch(actions.receiveProjectsError(e)))
    }
  }

  render(params) {
    const { project } = this.props
    return <ProjectForm onSubmit={this.handleSubmit(this.props.dispatch)} project={project} />
  }
}

const mapStateToProps = (state, ownProps) => ({
  projectId: ownProps.params.projectId,
  project: state.projects[ownProps.params.projectId]
})

export default withRouter(connect(mapStateToProps)(EditProject))
