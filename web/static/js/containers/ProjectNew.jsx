import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/projects'
import { createProject } from '../api'
import ProjectForm from '../components/ProjectForm'
import * as routes from '../routes'

class ProjectNew extends Component {
  handleSubmit() {
    const { router, dispatch } = this.props
    return (project) => {
      createProject(project)
        .then(project => dispatch(actions.createProject(project)))
        .then(() => router.push(routes.projects))
        .catch((e) => dispatch(actions.receiveProjectsError(e)))
    }
  }

  render(params) {
    const { project } = this.props
    return (
      <ProjectForm onSubmit={this.handleSubmit()} project={project} />
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  project: {}
})

export default withRouter(connect(mapStateToProps)(ProjectNew))
