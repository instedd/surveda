import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { InputWithLabel, ConfirmationModal, AudioDropzone, Dropdown, DropdownItem } from '../ui'
import { createAudio } from '../../api.js'
import * as questionnaireActions from '../../actions/questionnaire'
import classNames from 'classnames/bind'

type State = {
  audioErrors: string,
  audioId: any,
  audioSource: string,
  audioUri: string,
};

class IvrPrompt extends Component {

  state: State

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  stateFromProps(props) {
    const { ivrPrompt } = props

    let audioId = null

    if (ivrPrompt.audioSource === 'upload') {
      audioId = ivrPrompt.audioId
    }

    return {
      audioId: audioId,
      audioSource: ivrPrompt.audioSource || 'tts',
      audioUri: (ivrPrompt.audioId ? `/api/v1/audios/${ivrPrompt.audioId}` : ''),
      audioErrors: ''
    }
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  handleFileUpload(files) {
    const { stepId } = this.props
    createAudio(files)
      .then(response => {
        this.setState({audioUri: `/api/v1/audios/${response.result}`}, () => {
          this.props.questionnaireActions.changeStepAudioIdIvr(stepId, response.result)
          $('audio')[0].load()
        })
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

  render() {
    const { id, value, inputErrors, onChange, onBlur, changeIvrMode } = this.props

    return (
      <div>
        <div className='row'>
          <div className='col input-field s12'>
            <InputWithLabel id={id} value={value} label='Voice message' errors={inputErrors} >
              <input
                type='text'
                onChange={e => onChange(e)}
                onBlur={e => onBlur(e)}
                className={classNames({'invalid': inputErrors})}
              />
            </InputWithLabel>
          </div>
        </div>

        <div className='row audio-section'>
          <ConfirmationModal modalId='invalidTypeFile' modalText='The system only accepts MPEG and WAV files' header='Invalid file type' confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '600px'}} />
          <ConfirmationModal modalId='unprocessableEntity' header='Invalid file' modalText={this.state.audioErrors} confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '600px'}} />
          <div className='audio-dropdown'>
            <Dropdown className='step-mode underlined' label={this.state.audioSource == 'tts' ? <span className='v-middle'><i className='material-icons'>record_voice_over</i> Text to speech</span> : <span><i className='material-icons'>file_upload</i> Upload a file</span>} constrainWidth={false} dataBelowOrigin={false}>
              <DropdownItem>
                <a onClick={e => changeIvrMode(e, 'tts')}>
                  <i className='material-icons left'>record_voice_over</i>
                  Text to speech
                  {this.state.audioSource == 'tts' ? <i className='material-icons right'>done</i> : ''}
                </a>
              </DropdownItem>
              <DropdownItem>
                <a onClick={e => changeIvrMode(e, 'upload')}>
                  <i className='material-icons left'>file_upload</i>
                  Upload a file
                  {this.state.audioSource == 'upload' ? <i className='material-icons right'>done</i> : ''}
                </a>
              </DropdownItem>
            </Dropdown>
          </div>
          {(this.state.audioSource == 'upload')
            ? <div className='upload-audio'>
              <audio controls>
                <source src={this.state.audioUri} type='audio/mpeg' />
              </audio>
              <AudioDropzone onDrop={files => this.handleFileUpload(files)} onDropRejected={() => $('#invalidTypeFile').modal('open')} />
            </div>
            : ''}
        </div>
      </div>
    )
  }
}

IvrPrompt.propTypes = {
  id: PropTypes.string.isRequired,
  value: PropTypes.string.isRequired,
  inputErrors: PropTypes.bool,
  onChange: PropTypes.func.isRequired,
  onBlur: PropTypes.func.isRequired,
  changeIvrMode: PropTypes.func.isRequired,
  ivrPrompt: PropTypes.object.isRequired,
  questionnaireActions: PropTypes.any,
  stepId: PropTypes.string.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(null, mapDispatchToProps)(IvrPrompt)
