import React, { Component, PropTypes } from 'react'
import { browserHistory } from 'react-router'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/projects'
import { createProject } from '../api'
import ProjectForm from '../components/ProjectForm'

class CreateProject extends Component {
  handleSubmit(dispatch) {
    return (project) => {
      createProject(project)
        .then(project => dispatch(actions.createProject(project)))
        .then(() => browserHistory.push('/projects'))
        .catch((e) => dispatch(actions.receiveProjectsError(e)))
    }
  }

  render(params) {
    const { project } = this.props
    return (
      <ProjectForm onSubmit={this.handleSubmit(this.props.dispatch)} project={project} />
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  project: state.projects[ownProps.params.id] || {}
})

export default withRouter(connect(mapStateToProps)(CreateProject))
