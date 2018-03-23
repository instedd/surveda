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
    const { projectId, pageNumber } = this.props
    if (projectId) {
      this.props.actions.fetchActivities(projectId, pageNumber)
    }
  }

  nextPage(e) {
    e.preventDefault()

    const { projectId, pageNumber } = this.props
    this.props.actions.fetchActivities(projectId, pageNumber + 1)
  }

  previousPage(e) {
    e.preventDefault()

    const { projectId, pageNumber } = this.props
    this.props.actions.fetchActivities(projectId, pageNumber - 1)
  }

  sort() {
    const { projectId } = this.props
    this.props.actions.sortActivities(projectId)
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
            <SortableHeader text={t('Last activity')} property='insertedAt' sortBy={sortBy} sortAsc={sortAsc} onClick={() => this.sort()} />
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
  pageNumber: PropTypes.number.isRequired,
  pageSize: PropTypes.number.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

const mapStateToProps = (state, ownProps) => {
  let activities = orderedItems(state.activities.items, state.activities.order)
  const sortBy = state.activities.sortBy
  const sortAsc = state.activities.sortAsc
  const totalCount = state.activities.page.totalCount
  const pageNumber = state.activities.page.number
  const pageSize = state.activities.page.size
  const startIndex = (pageNumber - 1) * pageSize + 1
  const endIndex = Math.min(startIndex + pageSize - 1, totalCount)
  const hasPreviousPage = pageNumber > 1
  const hasNextPage = endIndex < totalCount

  return {
    projectId: ownProps.params.projectId,
    activities,
    totalCount,
    pageNumber,
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
