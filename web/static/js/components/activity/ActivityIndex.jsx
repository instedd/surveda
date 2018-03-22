import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import { orderedItems } from '../../reducers/collection'
import { CardTable, SortableHeader } from '../ui'
import ActivityDescription from './ActivityDescription'
import * as actions from '../../actions/activities'
import { translate } from 'react-i18next'

class ActivityIndex extends Component {
  componentDidMount() {
    const { projectId } = this.props
    if (projectId) {
      this.props.actions.fetchActivities(projectId)
    }
  }

  nextPage(e) {
    e.preventDefault()
    this.props.actions.nextActivitiesPage()
  }

  previousPage(e) {
    e.preventDefault()
    this.props.actions.previousActivitiesPage()
  }

  sortBy(property) {
    this.props.actions.sortActivitiesBy(property)
  }

  formatDate(date) {
    const locale = Intl.DateTimeFormat().resolvedOptions().locale || 'en-US'
    const options = {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      hour12: false
    }
    return date.toLocaleTimeString(locale, options)
  }

  render() {
    const { activities, totalCount, startIndex, endIndex, hasPreviousPage, hasNextPage, sortBy, sortAsc, t } = this.props

    if (!activities) {
      return (
        <div>
          <CardTable title={t('Loading activities...')} highlight />
        </div>
      )
    }

    const title = `${totalCount} ${(totalCount == 1) ? t('activity') : t('activities')}`
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

    return (<div>
      <CardTable title={title} footer={footer}>
        <thead>
          <tr>
            <th>{t('User')}</th>
            <th>{t('Action')}</th>
            <SortableHeader text={t('Last activity')} property='insertedAt' sortBy={sortBy} sortAsc={sortAsc} onClick={(name) => this.sortBy(name)} />
          </tr>
        </thead>
        <tbody>
          {activities.map(activity => {
            return (
              <tr key={activity.id}>
                <td>{activity.userName || activity.remoteIp}</td>
                <td>
                  <ActivityDescription activity={activity} />
                </td>
                <td>{this.formatDate(new Date(activity.insertedAt))}</td>
              </tr>
            )
          }) }
        </tbody>
      </CardTable>
    </div>)
  }
}

ActivityIndex.propTypes = {
  t: PropTypes.func,
  projectId: PropTypes.any.isRequired,
  actions: PropTypes.object.isRequired,
  activities: PropTypes.array,
  sortBy: PropTypes.string.isRequired,
  sortAsc: PropTypes.bool,
  totalCount: PropTypes.number.isRequired,
  startIndex: PropTypes.number.isRequired,
  endIndex: PropTypes.number.isRequired,
  hasPreviousPage: PropTypes.bool.isRequired,
  hasNextPage: PropTypes.bool.isRequired,
  pageSize: PropTypes.number.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

const mapStateToProps = (state, ownProps) => {
  let activities = orderedItems(state.activities.items, state.activities.order)
  const sortBy = state.activities.sortBy
  const sortAsc = state.activities.sortAsc
  const totalCount = activities ? activities.length : 0
  const pageIndex = state.activities.page.index
  const pageSize = state.activities.page.size
  if (activities) {
    activities = activities.slice(pageIndex, pageIndex + pageSize)
  }
  const startIndex = Math.min(totalCount, pageIndex + 1)
  const endIndex = Math.min(pageIndex + pageSize, totalCount)
  const hasPreviousPage = startIndex > 1
  const hasNextPage = endIndex < totalCount

  return {
    projectId: ownProps.params.projectId,
    activities,
    totalCount,
    pageSize,
    startIndex,
    endIndex,
    hasPreviousPage,
    hasNextPage,
    sortBy,
    sortAsc
  }
}

export default translate()(connect(mapStateToProps, mapDispatchToProps)(ActivityIndex))
