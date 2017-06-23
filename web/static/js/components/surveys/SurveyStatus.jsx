import React, { PureComponent } from 'react'
import TimeAgo from 'react-timeago'
import { Tooltip } from '../ui'
import { formatTimezone } from '../timezones/util'

export default class SurveyStatus extends PureComponent {
  static propTypes = {
    survey: React.PropTypes.object.isRequired,
    short: React.PropTypes.bool
  }

  nextCallDescription(survey, date) {
    if (this.props.short) {
      return <span>Scheduled at {this.hourDescription(survey, date)}</span>
    } else {
      return <span>Next call <TimeAgo date={date} /> at {this.hourDescription(survey, date)}</span>
    }
  }

  hourDescription(survey, date) {
    let hours = date.getHours()
    let amOrPm = 'am'
    if (hours >= 12) {
      amOrPm = 'pm'
      hours -= 12
    }
    return `${hours}${amOrPm} (${formatTimezone(survey.timezone)})`
  }

  render() {
    const { survey } = this.props

    if (!survey) {
      return <p>Loading...</p>
    }

    let icon = null
    let color = 'black-text'
    let text = null
    let tooltip = null

    switch (survey.state) {
      case 'not_ready':
        icon = 'mode_edit'
        text = 'Editing'
        break

      case 'ready':
        icon = 'play_circle_outline'
        text = 'Ready to launch'
        break

      case 'running':
        if (survey.nextScheduleTime) {
          icon = 'access_time'
          const date = new Date(survey.nextScheduleTime)
          text = this.nextCallDescription(survey, date)
        } else {
          icon = 'play_arrow'
          text = 'Running'
        }
        color = 'green-text'
        break

      case 'terminated':
        switch (survey.exitCode) {
          case 0:
            icon = 'done'
            text = 'Completed'
            break

          case 1:
            icon = 'error'
            text = 'Cancelled'
            tooltip = survey.exitMessage
            break

          default:
            icon = 'error'
            color = 'text-error'
            text = 'Failed'
            tooltip = survey.exitMessage
            break
        }
        break

      default:
        icon = 'warning'
        color = 'text-error'
        text = 'Unknown'
    }

    let component = (
      <span className='truncate'>
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
      <p className={color}>
        {component}
      </p>
    )
  }
}
