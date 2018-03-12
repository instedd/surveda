import React, { PureComponent, PropTypes } from 'react'
import TimeAgo from 'react-timeago'
import { Tooltip } from '../ui'
import { formatTimezone } from '../timezones/util'
import classNames from 'classnames/bind'
import { translate, Trans } from 'react-i18next'

class SurveyStatus extends PureComponent {
  static propTypes = {
    t: PropTypes.func,
    survey: PropTypes.object.isRequired,
    short: PropTypes.bool
  }

  constructor(props) {
    super(props)
    this.bindedFormatter = this.formatter.bind(this)
  }

  formatter(number, unit, suffix, date, defaultFormatter) {
    const { t } = this.props

    switch (unit) {
      case 'second':
        return t('{{count}} second from now', {count: number})
      case 'minute':
        return t('{{count}} minute from now', {count: number})
      case 'hour':
        return t('{{count}} hour from now', {count: number})
      case 'day':
        return t('{{count}} day from now', {count: number})
      case 'week':
        return t('{{count}} week from now', {count: number})
      case 'month':
        return t('{{count}} month from now', {count: number})
      case 'year':
        return t('{{count}} year from now', {count: number})
      default:
        return t('{{count}} {{unit}} {{text}}', {count: number, text: suffix, unit})
    }
  }

  nextCallDescription(survey, date) {
    const hour = this.hourDescription(survey, date)
    if (this.props.short) {
      return <Trans>Scheduled at {{hour}}</Trans>
    } else {
      return <Trans>Next contact <TimeAgo date={date} formatter={this.bindedFormatter} /> at {{hour}}</Trans>
    }
  }

  hourDescription(survey, date) {
    let locale = Intl.DateTimeFormat().resolvedOptions().locale || 'en-US'
    let options = {
      timeZone: survey.schedule.timezone,
      hour12: true,
      hour: 'numeric'
    }
    let time = date.toLocaleTimeString(locale, options)
    return `${time} (${formatTimezone(survey.schedule.timezone)})`
  }

  render() {
    const { survey, t } = this.props

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
        text = t('Editing', {context: 'survey'})
        break

      case 'ready':
        icon = 'play_circle_outline'
        text = t('Ready to launch', {context: 'survey'})
        break

      case 'running':
        if (survey.nextScheduleTime) {
          icon = 'access_time'
          const date = new Date(survey.nextScheduleTime)
          text = this.nextCallDescription(survey, date)
        } else {
          icon = 'play_arrow'
          text = t('Running', {context: 'survey'})
        }
        color = 'green-text'
        break

      case 'terminated':
        switch (survey.exitCode) {
          case 0:
            icon = 'done'
            text = t('Completed', {context: 'survey'})
            break

          case 1:
            icon = 'error'
            text = t('Cancelled', {context: 'survey'})
            tooltip = survey.exitMessage
            break

          default:
            icon = 'error'
            color = 'text-error'
            text = t('Failed', {context: 'survey'})
            tooltip = survey.exitMessage
            break
        }
        break

      default:
        icon = 'warning'
        color = 'text-error'
        text = t('Unknown', {context: 'survey'})
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
      <p className={classNames(color, 'truncate')}>
        {component}
      </p>
    )
  }
}

export default translate()(SurveyStatus)
