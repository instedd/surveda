import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { Input } from 'react-materialize'
import * as actions from '../../actions/survey'

class SurveyWizardChannelsStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    channels: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  channelChange(e) {
    e.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.selectChannels([e.target.value]))
  }

  render() {
    const { survey, channels } = this.props

    if (!survey || !channels) {
      return <div>Loading...</div>
    }

    const currentChannelId = (survey.channels && survey.channels.length > 0 ? survey.channels[survey.channels.length - 1] : null)

    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <h4>Select mode & channels</h4>
            <p className='flow-text'>
              Define which modes you want to use. You have to select a channel for each survey mode.
            </p>
          </div>
        </div>
        <div className='row'>
          <div className='input-field col s12'>
            <Input s={12} type='select' label='Channels'
              value={currentChannelId || ''}
              placeholder='Select a channel...'
              onChange={e => this.channelChange(e)}>
              { Object.keys(channels).map((channelId) =>
                <option key={channelId} id={channelId} name={channels[channelId].name} value={channelId}>
                  {channels[channelId].name}
                </option>
              )}
            </Input>
          </div>
        </div>
      </div>
    )
  }
}

export default connect()(SurveyWizardChannelsStep)
