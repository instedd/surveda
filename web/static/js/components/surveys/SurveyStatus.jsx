import React, { PureComponent } from 'react'
import TimeAgo from 'react-timeago'
import { Tooltip } from '../ui'

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
    return `${hours}${amOrPm} ${survey.timezone}`
  }

  render() {
    const { survey } = this.props

    if (!survey) {
      return <p>Loading...</p>
    }

    let time = null
    if (survey.state == 'running' && survey.nextScheduleTime) {
      const date = new Date(survey.nextScheduleTime)
      time = <p className='black-text'>
        <i className='material-icons survey-status'>access_time</i>
        {this.nextCallDescription(survey, date)}
      </p>
    }

    let icon = 'mode_edit'
    let color = 'black-text'
    let text = 'Editing'
    switch (survey.state) {
      case 'running':
        icon = 'play_arrow'
        color = 'green-text'
        text = 'Running'
        break
      case 'ready':
        icon = 'play_circle_outline'
        color = 'black-text'
        text = 'Ready to launch'
        break
      case 'terminated':
        switch (survey.exitCode) {
          case 0:
            icon = 'done'
            color = 'black-text'
            text = 'Completed'
            break
          case 1:
            icon = 'error'
            color = 'black-text'
            text = 'Cancelled'
            break
          case 3:
            icon = 'error'
            color = 'black-text'
            text = 'Failed'
            break
        }
        break
    }

    let component = (
      <span>
        <i className='material-icons survey-status'>{icon}</i>
        { text }
        { time }
      </span>
    )

    if (survey.exitCode != null && survey.exitCode != 0 && survey.exitMessage) {
      component = (
        <Tooltip text={survey.exitMessage} position='top'>
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
