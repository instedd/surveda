import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { Input } from 'react-materialize'
import * as actions from '../../actions/survey'
import values from 'lodash/values'
import flatMap from 'lodash/flatMap'
import uniq from 'lodash/uniq'
import some from 'lodash/some'
import isEqual from 'lodash/isEqual'

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

  modeChange(e, value) {
    const { dispatch } = this.props
    dispatch(actions.selectMode(value))
  }

  modeComparisonChange(e) {
    const { dispatch } = this.props
    dispatch(actions.changeModeComparison())
  }

  newChannelComponent(type, allChannels, currentChannels) {
    const currentChannel = currentChannels.find(id => allChannels[id].type == type)

    let label
    if (type == 'sms') {
      label = 'SMS'
    } else {
      label = 'Phone'
    }
    label += ' channel'

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

  modeIncludes(modes, target) {
    return some(modes, ary => isEqual(ary, target))
  }

  render() {
    const { survey, channels } = this.props

    if (!survey || !channels || ((survey.channels || []).length > 0 && Object.keys(channels).length == 0)) {
      return <div>Loading...</div>
    }

    const currentChannels = survey.channels || []
    const mode = survey.mode || []
    const modeComparison = (mode.length == 0 || mode.length > 1) ? true : survey.modeComparison

    let channelsComponent = []
    let allModes = uniq(flatMap(mode))
    for (const targetMode of allModes) {
      channelsComponent.push(this.newChannelComponent(targetMode, channels, currentChannels))
    }

    let inputType = modeComparison ? 'checkbox' : 'radio'

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
                id='questionnaire_mode_comparison'
                type='checkbox'
                defaultChecked={modeComparison}
                onClick={e => this.modeComparisonChange(e)}
                className='with-gap'
                />
              <label htmlFor='questionnaire_mode_comparison'>Run a comparison to contrast performance between different primary and fallback modes combinations (you can set up the allocations later in the comparisons section)</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_ivr'
                type={inputType}
                name='questionnaire_mode'
                className='with-gap'
                value='ivr'
                defaultChecked={this.modeIncludes(mode, ['ivr'])}
                onClick={e => this.modeChange(e, ['ivr'])}
                />
              <label htmlFor='questionnaire_mode_ivr'>Phone call</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_ivr_sms'
                type={inputType}
                name='questionnaire_mode'
                className='with-gap'
                value='ivr_sms'
                defaultChecked={this.modeIncludes(mode, ['ivr', 'sms'])}
                onClick={e => this.modeChange(e, ['ivr', 'sms'])}
                />
              <label htmlFor='questionnaire_mode_ivr_sms'>Phone call with SMS fallback</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_sms'
                type={inputType}
                name='questionnaire_mode'
                className='with-gap'
                value='sms'
                defaultChecked={this.modeIncludes(mode, ['sms'])}
                onClick={e => this.modeChange(e, ['sms'])}
                />
              <label htmlFor='questionnaire_mode_sms'>SMS</label>
            </p>
            <p>
              <input
                id='questionnaire_mode_sms_ivr'
                type={inputType}
                name='questionnaire_mode'
                className='with-gap'
                value='sms_ivr'
                defaultChecked={this.modeIncludes(mode, ['sms', 'ivr'])}
                onClick={e => this.modeChange(e, ['sms', 'ivr'])}
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
