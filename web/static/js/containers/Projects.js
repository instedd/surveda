import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link } from 'react-router'
import * as actions from '../actions/projects'
import { fetchProjects } from '../api'

class Projects extends Component {
  componentDidMount() {
    const { dispatch } = this.props
    fetchProjects().then(projects => dispatch(actions.fetchProjectsSuccess(projects)))
  }

  componentDidUpdate() {
  }

  render() {
    const { projects, ids } = this.props.projects
    return (
      <div>
        <Link className="btn-floating btn-large waves-effect waves-light green right mtop" to='/projects/new'>
          <i className="material-icons">add</i>
        </Link>
        <table className="white z-depth-1">
          <thead>
            <tr>
              <th>Name</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            { ids.map((project_id) =>
              <tr key={project_id}>
                <td>
                  <Link to={`/projects/${project_id}`}>{ projects[project_id].name }</Link>
                </td>
                <td>
                  <Link to={`/projects/${project_id}/edit`}>Edit</Link>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    )
  }
}

const mapStateToProps = (state) => {
  return {
    projects: state.projects
  }
}

export default connect(mapStateToProps)(Projects)
