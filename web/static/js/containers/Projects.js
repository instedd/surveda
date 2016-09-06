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
        <p style={{fontSize: 'larger'}}>
          <Link to='/projects/new'>Add project</Link>
        </p>
        <table style={{width: '300px'}}>
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
