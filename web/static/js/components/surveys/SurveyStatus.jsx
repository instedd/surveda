import React, { PureComponent } from 'react'

export default class SurveyStatus extends PureComponent {
  static propTypes = {
    survey: React.PropTypes.object.isRequired
  }

  render() {
    const { survey } = this.props

    if (!survey) {
      return <p>Loading...</p>
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
      case 'completed':
        icon = 'done'
        color = 'black-text'
        text = 'Completed'
        break
    }
    return (
      <p className={color}>
        <i className='material-icons survey-status'>{icon}</i>
        { text }
      </p>
    )
  }
}
