import React, { PureComponent, PropTypes } from 'react'
import { translate } from 'react-i18next'
import { connect } from 'react-redux'
import { formatTimezone } from '../timezones/util'
import { Tooltip } from '../ui'
import { fetchTimezones } from '../../actions/timezones'
import TimeAgo from 'react-timeago'
import classNames from 'classnames/bind'
import DownChannelsStatus from '../channels/DownChannelsStatus'
import dateformat from 'dateformat'
import map from 'lodash/map'
import min from 'lodash/min'
import i18n from '../../i18next'

class SurveyStatus extends PureComponent {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func.isRequired,
    survey: PropTypes.object.isRequired,
    short: PropTypes.bool,
    timezones: PropTypes.object,
    language: PropTypes.string
  }

  constructor(props) {
    super(props)
    this.bindedFormatter = this.formatter.bind(this)
    this.bindedStartedFormatter = this.startedFormatter.bind(this)
  }

  componentDidMount() {
    const { dispatch } = this.props
    dispatch(fetchTimezones())
  }

  formatter(number, unit, suffix, date, defaultFormatter) {
    const { t } = this.props

    switch (unit) {
      case 'second':
        return t('{{count}} second from now', { count: number })
      case 'minute':
        return t('{{count}} minute from now', { count: number })
      case 'hour':
        return t('{{count}} hour from now', { count: number })
      case 'day':
        return t('{{count}} day from now', { count: number })
      case 'week':
        return t('{{count}} week from now', { count: number })
      case 'month':
        return t('{{count}} month from now', { count: number })
      case 'year':
        return t('{{count}} year from now', { count: number })
    }
  }

  startedFormatter(number, unit, suffix, date, defaultFormatter) {
    const { t, survey } = this.props

    if (unit == 'second') {
      return t('Started {{count}} second ago', { count: number })
    } else if (unit == 'minute') {
      return t('Started {{count}} minute ago', { count: number })
    } else if (unit == 'hour') {
      return t('Started {{count}} hour ago', { count: number })
    } else if (unit == 'day') {
      return t('Started {{count}} day ago', { count: number })
    } else {
      return t('Started {{date}}', { date: dateformat(survey.startedAt, 'mmm d, yyyy HH:MM (Z)') })
    }
  }

  nextCallDescription(survey, date) {
    const { timezones, t, language } = this.props
    let options = {
      timeZone: timezones.items[survey.schedule.timezone],
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour12: true,
      hour: 'numeric'
    }
    let dateString = date.toLocaleDateString(language, options).replace(/[,]/g, '')
    if (language == 'es') dateString = dateString.replace(/a\..m\./, 'AM').replace(/p\..m\./, 'PM')
    const timezone = formatTimezone(survey.schedule.timezone)
    return t('Scheduled for {{dateString}} ({{timezone}})', {dateString, timezone})
  }

  surveyRanDescription(survey) {
    const { t } = this.props
    const formatDate = dateStr => dateformat(dateStr, 'yyyy-mm-dd')
    let startDate = formatDate(survey.startedAt)
    let endDate = formatDate(survey.endedAt)
    if (startDate === endDate) {
      return t('Ran only on {{startDate}}', { startDate })
    }
    return t('Ran from {{startDate}} to {{endDate}}', { startDate, endDate })
  }

  render() {
    const { survey, t, timezones } = this.props

    if (!survey) {
      return <p>{t('Loading...')}</p>
    }

    let icon = null
    let color = 'black-text'
    let text = null
    let tooltip = null

    switch (survey.state) {
      case 'not_ready':
        icon = 'mode_edit'
        text = t('Editing', { context: 'survey' })
        break

      case 'ready':
        icon = 'play_circle_outline'
        text = t('Ready to launch', { context: 'survey' })
        break

      case 'running':
        if (survey.downChannels.length > 0) {
          icon = 'cancel'
          const timestamp = min(map(survey.downChannels, (channel) => channel.timestamp))
          text = <DownChannelsStatus channels={survey.downChannels} timestamp={timestamp} />
          color = 'text-error'
          break
        } else {
          if (survey.nextScheduleTime) {
            if (timezones && timezones.items) {
              icon = 'access_time'
              const date = new Date(survey.nextScheduleTime)
              text = this.nextCallDescription(survey, date)
            }
          } else {
            icon = 'play_arrow'
            text = <TimeAgo date={survey.startedAt} live={false} formatter={this.bindedStartedFormatter} />
          }
          color = 'green-text'
          break
        }

      case 'terminated':
        let description = this.surveyRanDescription(survey)
        let status = state => t(`${state}. ${description}`, { context: 'survey' })
        switch (survey.exitCode) {
          case 0:
            icon = 'done'
            text = status('Completed')
            break

          case 1:
            icon = 'error'
            text = status('Cancelled')
            tooltip = survey.exitMessage
            break

          default:
            icon = 'error'
            color = 'text-error'
            text = status('Failed')
            tooltip = survey.exitMessage
            break
        }
        break
      case 'cancelling':
        switch (survey.exitCode) {
          case 1:
            icon = 'error'
            text = t('Cancelling', { context: 'survey' })
            tooltip = survey.exitMessage
            break

          default:
            icon = 'error'
            color = 'text-error'
            text = t('Failed', { context: 'survey' })
            tooltip = survey.exitMessage
            break
        }
        break

      default:
        icon = 'warning'
        color = 'text-error'
        text = t('Unknown', { context: 'survey' })
    }

    let component = (
      <span>
        <i className='material-icons survey-status'>{icon}</i>
        { text }
      </span>
    )

    if (tooltip) {
      component = (
        <Tooltip text={tooltip} position='top'>
          {component}
        </Tooltip>
      )
    }

    return (
      <p className={classNames(color, 'truncate', 'survey-status-container')}>
        {component}
      </p>
    )
  }
}

const mapStateToProps = (state) => {
  return {
    timezones: state.timezones,
    language: i18n.language
  }
}

export default translate()(connect(mapStateToProps)(SurveyStatus))
