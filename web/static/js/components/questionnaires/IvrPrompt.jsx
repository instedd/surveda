import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { ConfirmationModal, AudioDropzone, Dropdown, DropdownItem } from '../ui'
import Draft from './Draft'
import { createAudio } from '../../api.js'
import * as questionnaireActions from '../../actions/questionnaire'
import * as uiActions from '../../actions/ui'
import propsAreEqual from '../../propsAreEqual'
import { Preloader } from 'react-materialize'

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
    const { ivrPrompt, customHandlerFileUpload } = props

    let audioId = null

    if (ivrPrompt.audioSource === 'upload') {
      audioId = ivrPrompt.audioId
    }

    return {
      audioId: audioId,
      handleFileUpload: customHandlerFileUpload || this.genericHandlerFileUpload,
      audioSource: ivrPrompt.audioSource || 'tts',
      audioUri: (ivrPrompt.audioId ? `/api/v1/audios/${ivrPrompt.audioId}` : ''),
      audioErrors: ''
    }
  }

  componentWillReceiveProps(newProps) {
    if (propsAreEqual(this.props, newProps)) return

    this.setState(this.stateFromProps(newProps))
  }

  genericHandlerFileUpload = (files) => {
    const { stepId } = this.props
    this.props.uiActions.uploadAudio(stepId)
    createAudio(files)
      .then(response => {
        this.setState({audioUri: `/api/v1/audios/${response.result}`}, () => {
          this.props.questionnaireActions.changeStepAudioIdIvr(stepId, response.result)
          this.props.uiActions.finishAudioUpload()
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
    const { value, inputErrors, audioIdErrors, readOnly, changeIvrMode, autocomplete, autocompleteGetData, autocompleteOnSelect, uploadingAudio, stepId } = this.props
    let { label } = this.props
    if (!label) label = 'Voice message'

    const shouldDisplayErrors = value == this.props.originalValue

    let audioComponent = <AudioDropzone error={!!audioIdErrors} onDrop={files => this.state.handleFileUpload(files)} onDropRejected={() => $('#invalidTypeFile').modal('open')} />
    if (uploadingAudio && uploadingAudio == stepId) {
      let className = 'drop-text csv uploading'

      audioComponent =
        <div>
          <div className='drop-uploading'>
            <div className='preloader-wrapper active center'>
              <Preloader />
            </div>
          </div>
          <div className={className} />
        </div>
    }

    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <Draft
              label={label}
              value={value}
              errors={shouldDisplayErrors && inputErrors}
              readOnly={readOnly}
              onBlur={text => this.props.onBlur(text)}
              plainText
              autocomplete={autocomplete}
              autocompleteGetData={autocompleteGetData}
              autocompleteOnSelect={autocompleteOnSelect}
            />
          </div>
        </div>

        <div className='row audio-section'>
          <ConfirmationModal modalId='invalidTypeFile' modalText='The system only accepts MPEG and WAV files' header='Invalid file type' confirmationText='accept' style={{maxWidth: '600px'}} />
          <ConfirmationModal modalId='unprocessableEntity' header='Invalid file' modalText={this.state.audioErrors} confirmationText='accept' style={{maxWidth: '600px'}} />
          <div className='audio-dropdown'>
            <Dropdown className='step-mode underlined' readOnly={readOnly} label={this.state.audioSource == 'tts' ? <span className='v-middle'><i className='material-icons'>record_voice_over</i> Text to speech</span> : <span><i className='material-icons'>file_upload</i> Upload a file</span>} constrainWidth={false} dataBelowOrigin={false}>
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
              <audio controls key={this.state.audioId}>
                <source src={this.state.audioUri} type='audio/mpeg' />
              </audio>
              {readOnly ? null
                : audioComponent
              }
            </div>
            : ''}
        </div>
      </div>
    )
  }
}

IvrPrompt.propTypes = {
  label: PropTypes.string,
  customHandlerFileUpload: PropTypes.func,
  value: PropTypes.string.isRequired,
  originalValue: PropTypes.string.isRequired,
  inputErrors: PropTypes.array,
  audioIdErrors: PropTypes.array,
  onBlur: PropTypes.func.isRequired,
  autocomplete: PropTypes.bool.isRequired,
  autocompleteGetData: PropTypes.func.isRequired,
  autocompleteOnSelect: PropTypes.func.isRequired,
  changeIvrMode: PropTypes.func.isRequired,
  ivrPrompt: PropTypes.object.isRequired,
  readOnly: PropTypes.bool,
  questionnaireActions: PropTypes.any,
  uiActions: PropTypes.any,
  stepId: PropTypes.string,
  uploadingAudio: PropTypes.any
}

const mapStateToProps = (state) => ({
  uploadingAudio: state.ui.data.questionnaireEditor.uploadingAudio
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  uiActions: bindActionCreators(uiActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(IvrPrompt)
