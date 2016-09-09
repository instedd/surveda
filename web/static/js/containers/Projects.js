import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Link } from 'react-router'
import * as actions from '../actions/projects'

class Projects extends Component {
  componentDidMount() {
    const { dispatch } = this.props;
    dispatch(actions.fetchProjects());
  }

  render() {
    const { projects } = this.props
    return (
      <div>
        <Link className="btn-floating btn-large waves-effect waves-light green right mtop tooltipped" data-position="top" data-delay="20" data-tooltip="Add project" to='/projects/new'>
          <i className="material-icons">add</i>
        </Link>
        <table className="ncdtable">
          <thead>
            <tr>
              <th>Name</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            { Object.keys(projects).map((projectId) =>
              <tr key={projectId}>
                <td>
                  <Link to={`/projects/${projectId}`}>{ projects[projectId].name }</Link>
                </td>
                <td>
                  <Link to={`/projects/${projectId}/edit`}>Edit</Link>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  projects: state.projects
})

export default connect(mapStateToProps)(Projects)
