import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/projects'
import { fetchProject } from '../api'

class Project extends Component {
  componentDidMount() {
    const { dispatch, project_id } = this.props
    if(project_id){
      fetchProject(project_id).then(project => dispatch(actions.fetchProjectsSuccess(project)))
    } else {
      dispatch(actions.fetchProjectsError(`Id is not defined`))
    }
  }

  componentDidUpdate() {
  }

  render(params) {
    const { project } = this.props
    if(project) {
      return (
        <div>
          <h3>Project view</h3>
          <h4>Name: { project.name }</h4> 
          <br/>
          <br/>
          <Link to={`/projects/${project.id}/edit`}>Edit</Link>
          {' '}
          <Link to='/projects'>Back</Link>
          {' '}
          <Link to={`/projects/${project.id}/surveys`}>Surveys</Link>
        </div>
      )
    } else {
      return <p>Loading...</p>
    }
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    project_id: ownProps.params.id,
    project: state.projects.projects[ownProps.params.id]
  }
}

export default withRouter(connect(mapStateToProps)(Project))
