import React, { Component, PropTypes } from 'react'
import { browserHistory } from 'react-router'
import { connect } from 'react-redux'
//import { v4 } from 'node-uuid'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/projects'
import { fetchProjects, fetchProject, updateProject } from '../api'
import ProjectForm from '../components/ProjectForm'

class EditProject extends Component {
  componentDidMount() {
    const { dispatch, projectId } = this.props
    if(projectId) {
      fetchProject(projectId).then(project => dispatch(actions.fetchProjectsSuccess(project)))
    }
  }

  componentDidUpdate() {
  }

  handleSubmit(dispatch) {
    return (project) => {
      updateProject(project).then(project => dispatch(actions.updateProject(project))).then(() => browserHistory.push('/projects')).catch((e) => dispatch(actions.fetchProjectsError(e)))
    }
  }

  render(params) {
    let input
    const { project } = this.props
    return (<ProjectForm onSubmit={this.handleSubmit(this.props.dispatch)} project={project} />)
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.id,
    project: state.projects.projects[ownProps.params.id]
  }
}

export default withRouter(connect(mapStateToProps)(EditProject))
