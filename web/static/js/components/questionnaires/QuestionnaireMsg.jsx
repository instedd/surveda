import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { InputWithLabel, Card, Dropdown, DropdownItem, ConfirmationModal, AudioDropzone } from '../ui'
import * as actions from '../../actions/questionnaire'
import { createAudio } from '../../api.js'
import { decamelize } from 'humps'

class QuestionnaireMsg extends Component {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    questionnaire: PropTypes.object,
    messageKey: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired
  }

  constructor(props) {
    super(props)
    this.audioControl = null
    this.loadAudio = false
    this.state = {
      editing: false,
      audioErrors: null
    }
  }

  getIvr() {
    const { questionnaire, messageKey } = this.props

    const questionnaireMsg = questionnaire[messageKey] || {}
    const defaultLang = questionnaire.defaultLanguage
    return (questionnaireMsg[defaultLang] || {}).ivr || {}
  }

  handleClick() {
    this.setState({editing: !this.state.editing})
  }

  changeSmsText(e) {
    const { dispatch, messageKey } = this.props
    dispatch(actions.setSmsQuestionnaireMsg(messageKey, e.target.value))
  }

  changeIvrText(e) {
    const { dispatch, messageKey } = this.props
    const ivr = this.getIvr()

    dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
      ...ivr,
      text: e.target.value
    }))
  }

  changeIvrMode(e, mode) {
    e.preventDefault()

    const { dispatch, messageKey } = this.props
    const ivr = this.getIvr()

    dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
      ...ivr,
      audioSource: mode
    }))
  }

  handleFileUpload(files) {
    let self = this

    createAudio(files)
      .then(response => {
        const { dispatch, messageKey } = self.props
        const ivr = self.getIvr()
        self.loadAudio = true
        dispatch(actions.setIvrQuestionnaireMsg(messageKey, {
          ...ivr,
          audioId: response.result
        }))
      })
      .catch((e) => {
        e.json()
         .then((response) => {
           let errors = (response.errors.data || ['Only mp3 and wav files are allowed.']).join(' ')
           this.setState({audioErrors: errors})
           $('#unprocessableEntity').modal('open')
         })
      })
  }

  collapsed() {
    const { title } = self.props

    return (
      <ul className='collapsible dark'>
        <li>
          <Card>
            <div className='card-content closed-step'>
              <a className='truncate' href='#!' onClick={(e) => this.handleClick(e)}>
                <i className='material-icons left'>pie_chart</i>
                <span>{title} messages</span>
                <i className='material-icons right grey-text'>expand_more</i>
              </a>
            </div>

          </Card>
        </li>
      </ul>
    )
  }

  expanded() {
    const { questionnaire, messageKey, title } = this.props

    const questionnaireMsg = questionnaire[messageKey] || {}
    const defaultLang = questionnaire.defaultLanguage

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1

    let smsInput = null
    if (sms) {
      const smsMessage = ((questionnaireMsg || {})[defaultLang] || {}).sms || ''
      smsInput = (
        <div className='row' key={`${decamelize(messageKey, '-')}'-sms'`}>
          <div className='input-field'>
            <InputWithLabel value={smsMessage} label='SMS message' id={`${decamelize(messageKey)}'_sms'`}>
              <input
                type='text'
                onChange={e => this.changeSmsText(e)}
              />
            </InputWithLabel>
          </div>
        </div>
      )
    }

    let ivrTextInput = null
    let ivrFileInput = null
    if (ivr) {
      const ivrProperty = this.getIvr()
      const ivrText = ivrProperty.text || ''
      const ivrAudioSource = ivrProperty.audioSource
      const ivrAudioUri = ivrProperty.audioId ? `/api/v1/audios/${ivrProperty.audioId}` : ''

      ivrTextInput = (
        <div className='row' key={`${decamelize(messageKey, '-')}'-ivr'`}>
          <div className='input-field'>
            <InputWithLabel value={ivrText} label='Voice message' id={`${decamelize(messageKey, '-')}'-voice'`}>
              <input
                type='text'
                onChange={e => this.changeIvrText(e)}
              />
            </InputWithLabel>
          </div>
        </div>
      )

      let uploadComponent = null
      if (ivrAudioSource == 'upload') {
        uploadComponent = (
          <div className='upload-audio'>
            <audio controls ref={ref => { this.audioControl = ref }}>
              <source src={ivrAudioUri} type='audio/mpeg' />
            </audio>
            <AudioDropzone onDrop={files => this.handleFileUpload(files)} onDropRejected={() => $('#invalidTypeFile').modal('open')} />
          </div>
        )
      }

      ivrFileInput = (
        <div className='row audio-section'>
          <ConfirmationModal modalId='invalidTypeFile' modalText='The system only accepts MPEG and WAV files' header='Invalid file type' confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '600px'}} />
          <ConfirmationModal modalId='unprocessableEntity' header='Invalid file' modalText={this.state.audioErrors || ''} confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '600px'}} />
          <div className='audio-dropdown'>
            <Dropdown className='step-mode underlined' label={ivrAudioSource == 'tts' ? <span className='v-middle'><i className='material-icons'>record_voice_over</i> Text to speech</span> : <span><i className='material-icons'>file_upload</i> Upload a file</span>} constrainWidth={false} dataBelowOrigin={false}>
              <DropdownItem>
                <a onClick={e => this.changeIvrMode(e, 'tts')}>
                  <i className='material-icons left'>record_voice_over</i>
                  Text to speech
                  {ivrAudioSource == 'tts' ? <i className='material-icons right'>done</i> : ''}
                </a>
              </DropdownItem>
              <DropdownItem>
                <a onClick={e => this.changeIvrMode(e, 'upload')}>
                  <i className='material-icons left'>file_upload</i>
                  Upload a file
                  {ivrAudioSource == 'upload' ? <i className='material-icons right'>done</i> : ''}
                </a>
              </DropdownItem>
            </Dropdown>
          </div>
          {uploadComponent}
        </div>
      )
    }

    return (
      <Card>
        <ul className='collection collection-card dark'>
          <li className='collection-item header'>
            <div className='row'>
              <div className='col s12'>
                <i className='material-icons left'>pie_chart</i>
                <a className='page-title truncate'>
                  <span>{title} messages</span>
                </a>
                <a className='collapse right' href='#!' onClick={(e) => this.handleClick(e)}>
                  <i className='material-icons'>expand_less</i>
                </a>
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div>
              {smsInput}
              {ivrTextInput}
              {ivrFileInput}
            </div>
          </li>
        </ul>
      </Card>
    )
  }

  render() {
    if (!this.props.questionnaire) {
      return <div>Loading...</div>
    }

    if (this.state.editing) {
      return this.expanded()
    } else {
      return this.collapsed()
    }
  }

  componentDidUpdate() {
    if (this.loadAudio && this.audioControl) {
      this.loadAudio = false
      this.audioControl.load()
    }
  }
}

const mapStateToProps = (state) => ({
  questionnaire: state.questionnaire.data
})

export default connect(mapStateToProps)(QuestionnaireMsg)
