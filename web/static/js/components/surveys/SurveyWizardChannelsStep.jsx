import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { Input } from 'react-materialize'
import * as actions from '../../actions/survey'
import values from 'lodash/values'

class SurveyWizardChannelsStep extends Component {
  static propTypes = {
    survey: PropTypes.object.isRequired,
    channels: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  channelChange(e, type, allChannels) {
    e.preventDefault()
    const { dispatch, survey } = this.props

    let currentChannels = survey.channels || []
    currentChannels = currentChannels.filter(id => allChannels[id].type != type)
    if (e.target.value != '') {
      currentChannels.push(e.target.value)
    }
    dispatch(actions.selectChannels(currentChannels))
  }

  modeChange(e) {
    const { dispatch } = this.props
    dispatch(actions.selectMode(e.target.value.split('_')))
  }

  newChannelComponent(type, allChannels, currentChannels, index, total) {
    const currentChannel = currentChannels.find(id => allChannels[id].type == type)

    let label
    if (type == 'sms') {
      label = 'SMS'
    } else {
      label = 'Phone'
    }
    label += ' channel'
    if (total != 1) {
      if (index == 0) {
        label += ' (primary)'
      } else {
        label += ' (fallback)'
      }
    }

    let channels = values(allChannels)
    channels = channels.filter(c => c.type == type)

    return (
      <div className='row' key={type}>
        <div className='input-field col s12'>
          <Input s={12} type='select' label={label}
            value={currentChannel || ''}
            onChange={e => this.channelChange(e, type, allChannels)}>
            <option value=''>
            Select a channel...
            </option>
            { channels.map((channel) =>
              <option key={channel.id} value={channel.id}>
                {channel.name}
              </option>
              )}
          </Input>
        </div>
      </div>
    )
  }

  render() {
    const { survey, channels } = this.props

    if (!survey || !channels) {
      return <div>Loading...</div>
    }

    const currentChannels = survey.channels || []
    const mode = survey.mode ? survey.mode.join('_') : null

    let channelsComponent = []
    if (survey.mode) {
      for (let i = 0; i < survey.mode.length; i++) {
        channelsComponent.push(this.newChannelComponent(survey.mode[i], channels, currentChannels, i, survey.mode.length))
      }
    }

    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <h4>Select mode & channels</h4>
            <p className='flow-text'>
              Select which modes you want to use.
            </p>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <p>
              <input
                id='questionnaire_mode_ivr'
                type='radio'
                name='questionnaire_mode'
                className='with-gap'
                value='ivr'
                defaultChecked={mode == 'ivr'}
                onClick={e => this.modeChange(e)}
                />
              <label htmlFor='questionnaire_mode_ivr'>Phone call</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_ivr_sms'
                type='radio'
                name='questionnaire_mode'
                className='with-gap'
                value='ivr_sms'
                defaultChecked={mode == 'ivr_sms'}
                onClick={e => this.modeChange(e)}
                />
              <label htmlFor='questionnaire_mode_ivr_sms'>Phone call with SMS fallback</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_sms'
                type='radio'
                name='questionnaire_mode'
                className='with-gap'
                value='sms'
                defaultChecked={mode == 'sms'}
                onClick={e => this.modeChange(e)}
                />
              <label htmlFor='questionnaire_mode_sms'>SMS</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_sms_ivr'
                type='radio'
                name='questionnaire_mode'
                className='with-gap'
                value='sms_ivr'
                defaultChecked={mode == 'sms_ivr'}
                onClick={e => this.modeChange(e)}
                />
              <label htmlFor='questionnaire_mode_sms_ivr'>SMS with phone call fallback</label>
            </p>
          </div>
        </div>
        {channelsComponent}
      </div>
    )
  }
}

export default connect()(SurveyWizardChannelsStep)
