import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import * as channelActions from '../../actions/channels'
import { withRouter } from 'react-router'
import * as routes from '../../routes'
import { connect } from 'react-redux'
import { Modal, InputWithLabel } from '../ui'
import { Input } from 'react-materialize'
import * as api from '../../api'
import withQuestionnaire from './withQuestionnaire'
import { channelFriendlyName } from '../../channelFriendlyName'

class TestQuestionnaireModal extends Component {
  constructor(props) {
    super(props)

    this.state = {
      phoneNumber: '',
      mode: '',
      channelId: '',
      channelOptions: this.emptyChannelOptions(),
      sending: false
    }
  }

  componentDidMount() {
    this.props.channelActions.fetchChannels()
  }

  changePhoneNumber(e) {
    this.setState({phoneNumber: e.target.value})
  }

  changeMode(e) {
    const mode = e.target.value
    this.setState({
      mode,
      channelOptions: this.channelOptions(mode)
    })
  }

  changeChannelId(e) {
    this.setState({channelId: e.target.value})
  }

  send(e) {
    const { questionnaire, router } = this.props
    e.preventDefault()

    this.setState({sending: true}, () => {
      api.simulateQuestionnaire(questionnaire.projectId,
        questionnaire.id,
        this.state.phoneNumber,
        this.state.mode,
        this.state.channelId)
      .then(response => {
        this.refs.modal.close()

        const surveyId = response.result
        router.push(routes.surveySimulation(questionnaire.projectId, surveyId))
      })
    })
  }

  modeOptions() {
    const { questionnaire } = this.props
    const options = []

    options.push(<option key='none' value=''>Select mode...</option>)
    if (questionnaire.modes.indexOf('sms') != -1) {
      options.push(<option key='sms' value='sms'>SMS</option>)
    }
    if (questionnaire.modes.indexOf('ivr') != -1) {
      options.push(<option key='ivr' value='ivr'>Phone call</option>)
    }
    if (questionnaire.modes.indexOf('mobileweb') != -1) {
      options.push(<option key='mobileweb' value='mobileweb'>Mobile web</option>)
    }
    return options
  }

  channelOptions(mode) {
    const { channels } = this.props

    if (mode == '') return this.emptyChannelOptions()

    const type = mode == 'mobileweb' ? 'sms' : mode

    let channelOptions = []
    channelOptions.push(<option key={0} value=''>Select a channel...</option>)

    for (const channelId in channels) {
      const channel = channels[channelId]
      if (channel.type == type) {
        channelOptions.push(<option key={channel.id} value={channel.id}>{channel.name + channelFriendlyName(channel)}</option>)
      }
    }

    if (channelOptions.length == 1) {
      return this.noChannelsForThisMode()
    }

    return channelOptions
  }

  emptyChannelOptions() {
    return <option value=''>Select a mode first</option>
  }

  noChannelsForThisMode() {
    return <option value=''>No channels for this mode</option>
  }

  render() {
    const { modalId } = this.props

    let sendButton = null
    let cancelButton = <a href='#!' className='modal-action modal-close btn-flat grey-text'>Cancel</a>
    if (this.state.sending) {
      sendButton = <a className='btn-medium disabled'>Sending...</a>
      cancelButton = null
    } else if (this.state.phoneNumber.trim().length != 0 &&
      this.state.mode != '' &&
      this.state.channelId != '' &&
      this.state.channelOptions.length > 1) {
      sendButton = <a className='btn-large waves-effect waves-light blue modal-action' onClick={e => this.send(e)}>Send</a>
    } else {
      sendButton = <a className='btn-medium disabled'>Send</a>
    }

    return (
      <Modal card id={modalId} ref='modal' className='hidden-overflow'>
        <div className='modal-content'>
          <div className='card-title header'>
            <h5>Test sandbox</h5>
            <p>Test this questionnaire on a real device, the collected data will be ignored</p>
          </div>
          <div className='card-content'>
            <div className='row'>
              <InputWithLabel className='col s3 input-field' label='Phone number' value={this.state.phoneNumber}>
                <input type='text' onChange={e => this.changePhoneNumber(e)} />
              </InputWithLabel>
              <div className='col s1' />
              <Input s={2} type='select' value={this.state.mode} onChange={e => this.changeMode(e)} label='Mode'>
                {this.modeOptions()}
              </Input>
              <div className='col s1' />
              <Input s={5} type='select' value={this.state.channelId} onChange={e => this.changeChannelId(e)} label='Channel'>
                {this.state.channelOptions}
              </Input>
            </div>
            <br />
            <br />
            <br />
            <br />
            <br />
            <br />
            <br />
          </div>
          <div className='card-action'>
            {sendButton}
            {cancelButton}
          </div>
        </div>
      </Modal>
    )
  }
}

TestQuestionnaireModal.propTypes = {
  channelActions: PropTypes.object.isRequired,
  channels: PropTypes.object,
  modalId: PropTypes.string.isRequired,
  questionnaire: PropTypes.object,
  router: PropTypes.object
}

const mapStateToProps = (state) => ({
  channels: state.channels.items
})

const mapDispatchToProps = (dispatch) => ({
  channelActions: bindActionCreators(channelActions, dispatch)
})

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(withQuestionnaire(TestQuestionnaireModal)))
