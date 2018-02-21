import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { createProject } from '../../api'
import * as actions from '../../actions/projects'
import * as projectActions from '../../actions/project'
import { AddButton, EmptyPage, CardTable, SortableHeader, UntitledIfEmpty, Tooltip } from '../ui'
import * as routes from '../../routes'
import range from 'lodash/range'
import { orderedItems } from '../../reducers/collection'
import { FormattedDate } from 'react-intl'
import { Input } from 'react-materialize'

import { translate } from 'react-i18next'

class ProjectIndex extends Component {
  componentWillMount() {
    this.creatingProject = false

    this.props.projectActions.clearProject()
    this.props.actions.fetchProjects({'archived': false})
  }

  newProject(e) {
    e.preventDefault()

    // Prevent multiple clicks to create multiple projects
    if (this.creatingProject) return
    this.creatingProject = true

    const { router } = this.props

    let theProject
    createProject({name: ''})
        .then(response => {
          theProject = response.entities.projects[response.result]
          this.props.projectActions.createProject(theProject)
        })
        .then(() => {
          this.creatingProject = false
          router.push(routes.project(theProject.id))
        })
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

  archiveOrUnarchive(project: Project, action: string) {
    this.props.actions.archiveOrUnarchive(project, action)
  }

  fetchProjects(event: any) {
    const newValue = (event.target.value == 'archived')
    this.props.actions.fetchProjects({'archived': newValue})
  }

  archiveIconForProject(archived: boolean, project: Project) {
    if (!project.owner) {
      return <td />
    } else {
      if (archived) {
        return (
          <td className='action'>
            <Tooltip text='unarchive'>
              <a onClick={() => this.archiveOrUnarchive(project, 'unarchive')}>
                <i className='material-icons'>unarchive</i>
              </a>
            </Tooltip>
          </td>
        )
      } else {
        return (
          <td className='action'>
            <Tooltip text='archive'>
              <a onClick={() => this.archiveOrUnarchive(project, 'archive')}>
                <i className='material-icons'>archive</i>
              </a>
            </Tooltip>
          </td>
        )
      }
    }
  }

  render() {
    const { archived } = this.props

    const archivedFilter = <Input
      type='select'
      value={archived ? 'archive' : 'all_projects'}
      onChange={e => this.fetchProjects(e)}
      >
      <option key='archived' id='archived' name='archived' value='archived'> Archived </option>
      <option key='all_projects' id='all_projects' name='all_projects' value='all_projects'> All projects </option>
    </Input>

    return (
      <div>
        <AddButton text='Add project' onClick={e => this.newProject(e)} />
        <div className='row filterIndex'>
          {archivedFilter}
        </div>
        { this.renderTable() }
      </div>
    )
  }

  renderTable() {
    const { projects, sortBy, sortAsc, pageSize, startIndex, endIndex,
      totalCount, hasPreviousPage, hasNextPage, archived, router, t } = this.props

    if (!projects) {
      return (
        <div>
          <CardTable title='Loading projects...' highlight />
        </div>
      )
    }

    const title = `${totalCount} ${(totalCount == 1) ? t(' project') : t(' projects')}`
    const footer = (
      <div className='card-action right-align'>
        <ul className='pagination'>
          <li className='grey-text'>{startIndex}-{endIndex} of {totalCount}</li>
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
        { (projects.length == 0 && !archived)
          ? <div className='empty-projects'>
            <EmptyPage icon='folder' title={t('You have no projects yet')} onClick={e => this.newProject(e)} />
            <div className='organize'>
              <div className='icons'>
                <i className='material-icons'>assignment_turned_in</i>
                <i className='material-icons'>assignment</i>
                <i className='material-icons'>perm_phone_msg</i>
                <i className='material-icons'>folder_shared</i>
              </div>
              <p>
                <b>{t('Organize your work')}</b><br />
                {t('Manage surveys, questionnaires, and collaborators for each of your projects.')}
              </p>
            </div>
          </div>
          : <CardTable title={title} footer={footer} highlight>
            <colgroup>
              <col width='50%' />
              <col width='20%' />
              <col width='20%' />
              <col width='10%' />
            </colgroup>
            <thead>
              <tr>
                <SortableHeader text={t('Name')} property='name' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
                <SortableHeader className='right-align' text={t('Running surveys')} property='runningSurveys' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
                <SortableHeader className='right-align' text={t('Last activity date')} property='updatedAt' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
                <th />
              </tr>
            </thead>
            <tbody>
              { range(0, pageSize).map(index => {
                const project = projects[index]
                if (!project) return <tr key={-index} className='empty-row'><td colSpan='4' /></tr>

                return (
                  <tr key={project.id}>
                    <td className='project-name' onClick={() => router.push(routes.project(project.id))}>
                      <UntitledIfEmpty text={project.name} entityName={t('project')} />
                    </td>
                    <td className='right-align'>
                      {project.runningSurveys}
                    </td>
                    <td className='right-align'>
                      <FormattedDate
                        value={Date.parse(project.updatedAt)}
                        day='numeric'
                        month='short'
                        year='numeric' />
                    </td>
                    {
                      this.archiveIconForProject(archived, project)
                    }
                  </tr>
                )
              })
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
  sortBy: PropTypes.string,
  sortAsc: PropTypes.bool.isRequired,
  projects: PropTypes.array,
  pageSize: PropTypes.number.isRequired,
  startIndex: PropTypes.number.isRequired,
  endIndex: PropTypes.number.isRequired,
  hasPreviousPage: PropTypes.bool.isRequired,
  hasNextPage: PropTypes.bool.isRequired,
  totalCount: PropTypes.number.isRequired,
  archived: PropTypes.bool,
  t: PropTypes.func,
  router: PropTypes.object
}

const mapStateToProps = (state) => {
  let projects = orderedItems(state.projects.items, state.projects.order)
  const archived = projects ? state.projects.filter.archived : false
  const sortBy = state.projects.sortBy
  const sortAsc = state.projects.sortAsc
  const totalCount = projects ? projects.length : 0
  const pageIndex = state.projects.page.index
  const pageSize = state.projects.page.size
  if (projects) {
    projects = projects.slice(pageIndex, pageIndex + pageSize)
  }
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)
  const hasPreviousPage = startIndex > 1
  const hasNextPage = endIndex < totalCount
  return {
    sortBy,
    sortAsc,
    projects,
    pageSize,
    startIndex,
    endIndex,
    hasPreviousPage,
    hasNextPage,
    totalCount,
    archived
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch),
  projectActions: bindActionCreators(projectActions, dispatch)
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(ProjectIndex)))
