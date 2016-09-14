import React, { PropTypes, Component } from 'react'
import merge from 'lodash/merge'
import { Link, withRouter } from 'react-router'
import { connect } from 'react-redux'
import * as actions from '../actions/surveys'
import * as channelsActions from '../actions/channels'
import { updateSurvey } from '../api'

class SurveyChannelsStep extends Component {
  componentDidMount() {
    const { dispatch } = this.props;
    dispatch(channelsActions.fetchChannels());
  }

  handleSubmit(survey) {
    const { dispatch, projectId, router } = this.props
    updateSurvey(survey.projectId, survey)
      .then(survey => dispatch(actions.updateSurvey(survey)))
      .then(() => router.push(`/projects/${survey.projectId}/surveys/${survey.id}/edit`))
      .catch((e) => dispatch(actions.receiveSurveysError(e)))
  }

  render() {
    let input
    let channels_input = []
    const { survey, channels } = this.props

    if (!survey || !channels) {
      return <div>Loading...</div>
    }

    let survey_channels = Object.values(survey.channels)
    let current_channel_id = (survey_channels.length > 0 ? survey_channels[survey_channels.length - 1].channelId : null)

    return (
      <div>
        <div>
          <label>Select mode & channels </label>
          <div>
            Define which modes you want to use. You have to select a channel for each survey mode.
          </div>
        </div>
        <h6> Channels </h6>
        <select style={{display: 'block'}} defaultValue={current_channel_id}>
        { Object.keys(channels).map((channel_id) =>
          <option key={channel_id} id={channel_id} name="channel" value={ channel_id } ref={ node => {channels_input.push({id: channel_id, node:node})}} >
            {channels[channel_id].name}
          </option>
        )}
        </select>
        <button type="button" onClick={() =>
          this.handleSubmit(merge({}, survey, {channel_id: channels_input.find(element => element.node.selected).id }))
        }>
          Submit
        </button>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  channels: state.channels,
  survey: state.surveys[ownProps.params.id]
})

export default withRouter(connect(mapStateToProps)(SurveyChannelsStep));
