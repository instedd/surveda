import React, { Component } from 'react'
import merge from 'lodash/merge'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import * as actions from '../actions/surveys'
import * as channelsActions from '../actions/channels'
import { updateSurvey } from '../api'
import * as routes from '../routes'

class SurveyWizardChannelsStep extends Component {
  componentDidMount() {
    const { dispatch } = this.props
    dispatch(channelsActions.fetchChannels())
  }

  handleSubmit(survey) {
    const { dispatch, router } = this.props
    updateSurvey(survey.projectId, survey)
      .then(updatedSurvey => dispatch(actions.setSurvey(updatedSurvey)))
      .then(() => router.push(routes.editSurveySchedule(survey.projectId, survey.id)))
      .catch((e) => dispatch(actions.receiveSurveysError(e)))
  }

  render() {
    const channelsInput = []
    const { survey, channels } = this.props

    if (!survey || !channels) {
      return <div>Loading...</div>
    }

    const currentChannelId = (survey.channels.length > 0 ? survey.channels[survey.channels.length - 1] : null)

    return (
      <div className='col s12 m7 offset-m1'>
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
            <select defaultValue={currentChannelId} ref={ref => $(ref).material_select()}>
              <option name='channel'>Select a channel...</option>
              { Object.keys(channels).map((channelId) =>
                <option key={channelId} id={channelId} name='channel' value={channelId} ref={node => { channelsInput.push({id: channelId, node: node}) }} >
                  {channels[channelId].name}
                </option>
              )}
            </select>
            <label> Channels </label>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <button className='btn waves-effect waves-light' type='button' onClick={() => {
              const option = channelsInput.find(element => element.node.selected)
              const selectedChannels = option ? [parseInt(option.id, 10)] : []
              const merged = merge({}, survey)
              merged.channels = selectedChannels
              this.handleSubmit(merged)
            }}>
              Next
            </button>
          </div>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  channels: state.channels,
  survey: state.surveys[ownProps.params.surveyId]
})

export default withRouter(connect(mapStateToProps)(SurveyWizardChannelsStep))
