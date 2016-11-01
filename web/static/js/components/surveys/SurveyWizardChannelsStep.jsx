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
    const channels = e.target.value == '' ? [] : [e.target.value]
    dispatch(actions.selectChannels(channels))
  }

  modeChange(e) {
    const { dispatch } = this.props
    dispatch(actions.selectMode(e.target.value.split('_')))
  }

  render() {
    const { survey, channels } = this.props

    if (!survey || !channels) {
      return <div>Loading...</div>
    }

    const currentChannelId = (survey.channels && survey.channels.length > 0 ? survey.channels[survey.channels.length - 1] : null)
    const mode = survey.mode ? survey.mode.join('_') : null

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
        <div className='row'>
          <div className='input-field col s12'>
            <Input s={12} type='select' label='Channels'
              value={currentChannelId || ''}
              onChange={e => this.channelChange(e)}>
              <option value=''>
                Select a channel...
              </option>
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
