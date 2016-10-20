import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/project'
import { createProject } from '../api'
import ProjectForm from '../components/ProjectForm'
import * as routes from '../routes'

class ProjectNew extends Component {
  handleSubmit() {
    const { router } = this.props
    let theProject
    return (project) => {
      createProject(project)
        .then(response => {
          theProject = response.entities.projects[response.result]
          this.props.actions.createProject(theProject)
        })
        .then(() => router.push(routes.project(theProject.id)))
    }
  }

  render(params) {
    const { project } = this.props
    return (
      <ProjectForm onSubmit={this.handleSubmit()} project={project} />
    )
  }
}

ProjectNew.propTypes = {
  actions: PropTypes.object.isRequired,
  project: PropTypes.object,
  router: PropTypes.object
}

const mapStateToProps = (state, ownProps) => ({
  project: {}
})

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ProjectNew))
