import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/projects'
import * as projectActions from '../actions/project'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'
import CardTable from '../components/CardTable'
import UntitledIfEmpty from '../components/UntitledIfEmpty'
import * as routes from '../routes'

class ProjectIndex extends Component {
  componentWillMount() {
    this.props.projectActions.clearProject()
    this.props.actions.fetchProjects()
  }

  render() {
    const { fetching, projects, router } = this.props
    if (fetching || !projects) {
      return (
        <div>
          <CardTable title='Loading projects...' highlight />
        </div>
      )
    }

    const title = `${Object.keys(projects).length} ${(Object.keys(projects).length === 1) ? ' project' : ' projects'}`

    return (
      <div>
        <AddButton text='Add project' linkPath={routes.newProject} />
        { (Object.keys(projects).length === 0)
          ? <EmptyPage icon='assignment_turned_in' title='You have no projects yet' linkPath={routes.newProject} />
          : <CardTable title={title} highlight>
            <thead>
              <tr>
                <th>Name</th>
              </tr>
            </thead>
            <tbody>
              { Object.keys(projects).map((projectId) =>
                <tr key={projectId}>
                  <td onClick={() => router.push(routes.project(projectId))}>
                    <UntitledIfEmpty text={projects[projectId].name} />
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

ProjectIndex.propTypes = {
  actions: PropTypes.object.isRequired,
  projectActions: PropTypes.object.isRequired,
  fetching: PropTypes.bool.isRequired,
  projects: PropTypes.object,
  router: PropTypes.object
}

const mapStateToProps = (state) => ({
  projects: state.projects.items,
  fetching: state.projects.fetching
})

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ProjectIndex))
