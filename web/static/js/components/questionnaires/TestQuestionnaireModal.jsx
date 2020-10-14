import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import * as channelActions from '../../actions/channels'
import { withRouter } from 'react-router'
import * as routes from '../../routes'
import { connect } from 'react-redux'
import { Modal, InputWithLabel, channelFriendlyName } from '../ui'
import { Input } from 'react-materialize'
import * as api from '../../api'
import withQuestionnaire from './withQuestionnaire'
import { translate } from 'react-i18next'

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
      const {phoneNumber, mode, channelId} = this.state
      const phoneNumberToBeSent = mode == 'mobileweb' && this.isEmptyOrWhiteSpace(phoneNumber)
        // We don't care about the number, but the backend expects the respondent to have one
        // Without this number, no message will be sent and so, no message will be shown
        ? '9999999999'
        : phoneNumber
      api.simulateQuestionnaire(questionnaire.projectId,
        questionnaire.id,
        phoneNumberToBeSent,
        mode,
        channelId)
      .then(response => {
        this.refs.modal.close()

        const surveyId = response.result
        router.push(routes.surveySimulation(questionnaire.projectId, surveyId, mode))
      })
    })
  }

  modeOptions() {
    const { questionnaire, t } = this.props
    const options = []

    options.push(<option key='none' value=''>{t('Select mode...')}</option>)
    if (questionnaire.modes.indexOf('sms') != -1) {
      options.push(<option key='sms' value='sms'>{t('SMS')}</option>)
    }
    if (questionnaire.modes.indexOf('ivr') != -1) {
      options.push(<option key='ivr' value='ivr'>{t('Phone call')}</option>)
    }
    if (questionnaire.modes.indexOf('mobileweb') != -1) {
      options.push(<option key='mobileweb' value='mobileweb'>{t('Mobile web')}</option>)
    }
    return options
  }

  channelOptions(mode) {
    const { channels, t } = this.props

    if (mode == '') return this.emptyChannelOptions()

    const type = mode == 'mobileweb' ? 'sms' : mode

    let channelOptions = []
    channelOptions.push(<option key={0} value=''>{t('Select a channel...')}</option>)

    if (mode == 'sms') channelOptions.push(<option key='simulation' value='simulation'>{t('Simulation')}</option>)

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

  isEmptyOrWhiteSpace(s) {
    return s.trim().length == 0
  }

  render() {
    const { modalId, questionnaire, router, t } = this.props
    const { mode, phoneNumber } = this.state
    const isValidPhoneNumber = mode == 'mobileweb' || !this.isEmptyOrWhiteSpace(phoneNumber)
    const activeButton = ({ onClick }) => <a className='btn-large waves-effect waves-light blue modal-action' onClick={onClick}>Send</a>
    let sendButton = null
    let cancelButton = <a href='#!' className='modal-action modal-close btn-flat grey-text'>Cancel</a>
    if (this.state.channelId == 'simulation') {
      sendButton = activeButton({
        onClick: () => {
          this.refs.modal.close()
          router.push(routes.questionnaireSimulation(questionnaire.projectId, questionnaire.id, mode))
        }
      })
    } else if (this.state.sending) {
      sendButton = <a className='btn-medium disabled'>{t('Sending...')}</a>
      cancelButton = null
    } else if (isValidPhoneNumber &&
      mode != '' &&
      this.state.channelId != '' &&
      this.state.channelOptions.length > 1) {
      sendButton = activeButton({ onClick: e => this.send(e) })
    } else {
      sendButton = <a className='btn-medium disabled'>{t('Send')}</a>
    }

    return (
      <Modal card id={modalId} ref='modal' className='hidden-overflow'>
        <div className='modal-content'>
          <div className='card-title header'>
            <h5>{t('Test sandbox')}</h5>
            <p>{t('Test this questionnaire on a real device, the collected data will be ignored')}</p>
          </div>
          <div className='card-content'>
            <div className='row'>
              <InputWithLabel className='col s3 input-field' label={t('Phone number')} value={this.state.phoneNumber}>
                <input type='text' onChange={e => this.changePhoneNumber(e)} />
              </InputWithLabel>
              <div className='col s1' />
              <Input s={2} type='select' value={this.state.mode} onChange={e => this.changeMode(e)} label={t('Mode')}>
                {this.modeOptions()}
              </Input>
              <div className='col s1' />
              <Input s={5} type='select' value={this.state.channelId} onChange={e => this.changeChannelId(e)} label={t('Channel')}>
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
  router: PropTypes.object,
  t: PropTypes.func
}

const mapStateToProps = (state) => ({
  channels: state.channels.items
})

const mapDispatchToProps = (dispatch) => ({
  channelActions: bindActionCreators(channelActions, dispatch)
})

export default translate()(withRouter(connect(mapStateToProps, mapDispatchToProps)(withQuestionnaire(TestQuestionnaireModal))))
