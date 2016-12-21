import React, { Component, PropTypes } from 'react'
import { InputWithLabel, ConfirmationModal, AudioDropzone, Dropdown, DropdownItem } from '../ui'
import classNames from 'classnames/bind'

class IvrPrompt extends Component {

  render() {
    const { id, value, inputErrors, onChange, onBlur, changeIvrMode, audioErrors, audioSource, audioUri, handleFileUpload } = this.props

    return (
      <div>
        <div className='row'>
          <div className='col input-field s12'>
            <InputWithLabel id={id} value={value} label='Voice message' >
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
          <ConfirmationModal modalId='unprocessableEntity' header='Invalid file' modalText={audioErrors} confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '600px'}} />
          <div className='audio-dropdown'>
            <Dropdown className='step-mode underlined' label={audioSource == 'tts' ? <span className='v-middle'><i className='material-icons'>record_voice_over</i> Text to speech</span> : <span><i className='material-icons'>file_upload</i> Upload a file</span>} constrainWidth={false} dataBelowOrigin={false}>
              <DropdownItem>
                <a onClick={e => changeIvrMode(e, 'tts')}>
                  <i className='material-icons left'>record_voice_over</i>
              Text to speech
                  {audioSource == 'tts' ? <i className='material-icons right'>done</i> : ''}
                </a>
              </DropdownItem>
              <DropdownItem>
                <a onClick={e => changeIvrMode(e, 'upload')}>
                  <i className='material-icons left'>file_upload</i>
                  Upload a file
                  {audioSource == 'upload' ? <i className='material-icons right'>done</i> : ''}
                </a>
              </DropdownItem>
            </Dropdown>
          </div>
          {(audioSource == 'upload')
            ? <div className='upload-audio'>
              <audio controls>
                <source src={audioUri} type='audio/mpeg' />
              </audio>
              <AudioDropzone onDrop={files => handleFileUpload(files)} onDropRejected={() => $('#invalidTypeFile').modal('open')} />
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
  audioErrors: PropTypes.string.isRequired,
  audioSource: PropTypes.string.isRequired,
  audioUri: PropTypes.string.isRequired,
  handleFileUpload: PropTypes.func.isRequired
}

export default IvrPrompt
