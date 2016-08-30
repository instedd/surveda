import React, { Component, PropTypes } from 'react'
import { browserHistory } from 'react-router'
import { connect } from 'react-redux'
//import { v4 } from 'node-uuid'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/projects'
import { fetchProjects, fetchProject, createProject } from '../api'
import Project from './Project'
import ProjectForm from '../components/ProjectForm'

class CreateProject extends Component {
  componentDidUpdate() {
  }

  handleSubmit(dispatch) {
    return (project) => {
      createProject(project)
        .then(project => dispatch(actions.createProject(project)))
        .then(() => browserHistory.push('/projects'))
        .catch((e) => dispatch(actions.fetchProjectsError(e)))
    }
  }

  render(params) {
    let input
    const { project } = this.props
    return (
      <ProjectForm onSubmit={this.handleSubmit(this.props.dispatch)} project={project} />
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    project: state.projects.projects[ownProps.params.id] || {}
  }
}

export default withRouter(connect(mapStateToProps)(CreateProject))
