import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import * as actions from '../actions/projects'
import * as projectActions from '../actions/project'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'
import CardTable from '../components/CardTable'
import SortableHeader from '../components/SortableHeader'
import UntitledIfEmpty from '../components/UntitledIfEmpty'
import * as routes from '../routes'
import values from 'lodash/values'
import range from 'lodash/range'

class ProjectIndex extends Component {
  componentWillMount() {
    this.props.projectActions.clearProject()
    this.props.actions.fetchProjects()
  }

  nextPage(e) {
    e.preventDefault()
    this.props.actions.nextProjectsPage()
  }

  previousPage(e) {
    e.preventDefault()
    this.props.actions.previousProjectsPage()
  }

  sortBy(property) {
    this.props.actions.sortProjectsBy(property)
  }

  render() {
    const { fetching, projects, sortBy, sortAsc, pageSize, startIndex, endIndex,
      totalCount, hasPreviousPage, hasNextPage, router } = this.props

    if (fetching && !projects) {
      return (
        <div>
          <CardTable title='Loading projects...' highlight />
        </div>
      )
    }

    const title = `${Object.keys(projects).length} ${(Object.keys(projects).length === 1) ? ' project' : ' projects'}`
    const footer = (
      <div className='right-align'>
        <ul className='pagination'>
          <li><span className='grey-text'>{startIndex}-{endIndex} of {totalCount}</span></li>
          { hasPreviousPage
            ? <li><a href='#!' onClick={e => this.previousPage(e)}><i className='material-icons'>chevron_left</i></a></li>
            : <li className='disabled'><i className='material-icons'>chevron_left</i></li>
          }
          { hasNextPage
            ? <li><a href='#!' onClick={e => this.nextPage(e)}><i className='material-icons'>chevron_right</i></a></li>
            : <li className='disabled'><i className='material-icons'>chevron_right</i></li>
          }
        </ul>
      </div>
    )

    return (
      <div>
        <AddButton text='Add project' linkPath={routes.newProject} />
        { (Object.keys(projects).length === 0)
          ? <EmptyPage icon='assignment_turned_in' title='You have no projects yet' linkPath={routes.newProject} />
          : <CardTable title={title} footer={footer} highlight>
            <thead>
              <tr>
                <SortableHeader text='Name' property='name' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
              </tr>
            </thead>
            <tbody>
              { range(0, pageSize).map(index => {
                const project = projects[index]
                if (!project) return <tr key={index}><td>&nbsp;</td></tr>

                return (
                  <tr key={index}>
                    <td onClick={() => router.push(routes.project(project.id))}>
                      <UntitledIfEmpty text={project.name} />
                    </td>
                  </tr>
                ) })
              }
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
  sortBy: PropTypes.string,
  sortAsc: PropTypes.bool.isRequired,
  projects: PropTypes.array,
  pageSize: PropTypes.number.isRequired,
  startIndex: PropTypes.number.isRequired,
  endIndex: PropTypes.number.isRequired,
  hasPreviousPage: PropTypes.bool.isRequired,
  hasNextPage: PropTypes.bool.isRequired,
  totalCount: PropTypes.number.isRequired,
  router: PropTypes.object
}

const mapStateToProps = (state) => {
  let projects = state.projects.items ? values(state.projects.items) : []
  const fetching = state.projects.fetching
  const sortBy = state.projects.sortBy
  const sortAsc = state.projects.sortAsc
  sortProjects(projects, sortBy, sortAsc)
  const totalCount = projects.length
  const pageIndex = state.projects.page.index
  const pageSize = state.projects.page.size
  projects = projects.slice(pageIndex, pageIndex + pageSize)
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)
  const hasPreviousPage = startIndex > 1
  const hasNextPage = endIndex < totalCount
  return {
    fetching,
    sortBy,
    sortAsc,
    projects,
    pageSize,
    startIndex,
    endIndex,
    hasPreviousPage,
    hasNextPage,
    totalCount
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch)
})

const sortProjects = (projects, sortBy, sortAsc) => {
  if (!sortBy) return

  projects.sort((p1, p2) => {
    let x1 = p1[sortBy]
    let x2 = p2[sortBy]

    if (typeof (x1) === 'string') x1 = x1.toLowerCase()
    if (typeof (x2) === 'string') x2 = x2.toLowerCase()

    if (x1 < x2) {
      return sortAsc ? -1 : 1
    } else if (x1 > x2) {
      return sortAsc ? 1 : -1
    } else {
      return 0
    }
  })
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ProjectIndex))
