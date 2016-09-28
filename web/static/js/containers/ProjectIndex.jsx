import React, { Component } from 'react'
import { connect } from 'react-redux'
import { Link, withRouter } from 'react-router'
import * as actions from '../actions/projects'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'
import CardTable from '../components/CardTable'

class ProjectIndex extends Component {
  componentDidMount() {
    const { dispatch } = this.props;
    dispatch(actions.fetchProjects());
  }

  render() {
    const { projects, router } = this.props
    const title = `${Object.keys(projects).length} ${(Object.keys(projects).length == 1) ? ' project' : ' projects'}`

    return (
      <div>
        <AddButton text="Add project" linkPath='/projects/new' />
        { (Object.keys(projects).length == 0) ?
          <EmptyPage icon='assignment_turned_in' title='You have no projects yet' linkPath='/projects/new' />
        :
          <CardTable title={ title } highlight={true}>
            <thead>
              <tr>
                <th>Name</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              { Object.keys(projects).map((projectId) =>
                <tr key={projectId}>
                  <td onClick={() => router.push(`/projects/${projectId}`)}>
                    {projects[projectId].name}
                  </td>
                  <td onClick={() => router.push(`/projects/${projectId}/edit`)}>
                    Edit
                  </td>
                </tr>
              )}
            </tbody>
          </CardTable>
        }
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  projects: state.projects
})

export default withRouter(connect(mapStateToProps)(ProjectIndex))
