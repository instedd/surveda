import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { EditableTitleLabel, Card, Dropdown, DropdownItem, ConfirmationModal } from '../ui'
import * as questionnaireActions from '../../actions/questionnaire'
import StepMultipleChoiceEditor from './StepMultipleChoiceEditor'
import StepNumericEditor from './StepNumericEditor'
import classNames from 'classnames/bind'
import Dropzone from 'react-dropzone'
import { createAudio } from '../../api.js'

const AudioDropzone = ({ onDrop, onDropRejected }) => {
  return (
    <Dropzone className='dropfile audio' activeClassName='active' rejectClassName='rejectedfile' multiple={false} onDrop={onDrop} onDropRejected={onDropRejected} accept='audio/*' >
      <div className='drop-icon' />
      <div className='drop-text audio' />
    </Dropzone>
  )
}

class StepEditor extends Component {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  stepTitleChange(e) {
    e.preventDefault()
    this.setState({stepTitle: e.target.value})
  }

  stepTitleSubmit(value) {
    const { step } = this.props
    this.props.questionnaireActions.changeStepTitle(step.id, value)
  }

  changeStepType(type) {
    const { step } = this.props
    this.props.questionnaireActions.changeStepType(step.id, type)
  }

  stepPromptSmsChange(e) {
    e.preventDefault()
    this.setState({stepPromptSms: e.target.value})
  }

  stepPromptSmsSubmit(e) {
    e.preventDefault()
    const { step } = this.props
    this.props.questionnaireActions.changeStepPromptSms(step.id, e.target.value)
  }

  stepPromptIvrChange(e) {
    e.preventDefault()
    this.setState({stepPromptIvr: e.target.value})
  }

  stepPromptIvrSubmit(e) {
    e.preventDefault()
    const { step } = this.props
    this.props.questionnaireActions.changeStepPromptIvr(step.id, {text: e.target.value, audioSource: 'tts'})
  }

  stepStoreChange(e) {
    e.preventDefault()
    this.setState({stepStore: e.target.value})
  }

  stepStoreSubmit(e) {
    e.preventDefault()
    const { step } = this.props
    this.props.questionnaireActions.changeStepStore(step.id, e.target.value)
  }

  delete(e) {
    e.preventDefault()
    const { onDelete } = this.props
    onDelete()
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  changeIvrMode(e, mode) {
    const { step } = this.props
    this.props.questionnaireActions.changeStepPromptIvr(step.id, {text: this.state.stepPromptIvr, audioSource: mode})
  }

  stateFromProps(props) {
    const { step } = props
    return {
      stepTitle: step.title,
      stepType: step.type,
      stepPromptSms: step.prompt.sms || '',
      stepPromptIvr: (step.prompt.ivr || {}).text || '',
      stepStore: step.store || '',
      audioId: (step.prompt.ivr || {}).audioId,
      audioSource: (step.prompt.ivr || {}).audioSource || 'tts',
      audioSrc: (step.prompt.ivr && step.prompt.ivr.audioId ? `/api/v1/audios/${step.prompt.ivr.audioId}` : ''),
      audioErrors: ''
    }
  }

  handleFileUpload(files) {
    const { step } = this.props
    createAudio(files)
      .then(response => {
        this.setState({audioSrc: `/api/v1/audios/${response.result}`}, () => {
          this.props.questionnaireActions.changeStepAudioIdIvr(step.id, response.result)
          $('audio')[0].load()
        })
      })
      .catch((e) => {
        e.json()
         .then((response) => {
           let errors = response.errors.data.join(' ')
           this.setState({audioErrors: errors})
           $('#unprocessableEntity').modal('open')
         })
      })
  }

  render() {
    const { step, onCollapse, questionnaire, skip } = this.props

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1

    let editor
    if (step.type == 'multiple-choice') {
      editor = <StepMultipleChoiceEditor step={step} skip={skip} sms={sms} ivr={ivr} />
    } else if (step.type == 'numeric') {
      editor = <StepNumericEditor step={step} />
    } else {
      throw new Error(`unknown step type: ${step.type}`)
    }

    let smsInput = null
    if (sms) {
      smsInput = <div className='row'>
        <div className='col input-field s12'>
          <input
            id='step_editor_sms_prompt'
            type='text'
            is length='140'
            value={this.state.stepPromptSms}
            onChange={e => this.stepPromptSmsChange(e)}
            onBlur={e => this.stepPromptSmsSubmit(e)}
            ref={ref => $(ref).characterCounter()} />
          <label htmlFor='step_editor_sms_prompt' className={classNames({'active': this.state.stepPromptSms != ''})}>SMS message</label>
        </div>
      </div>
    }

    let ivrInput = null
    let ivrTextInput = null
    let ivrFileInput = null

    if (ivr) {
      ivrTextInput = <div className='row'>
        <div className='col input-field s12'>
          <input
            id='step_editor_voice_message'
            type='text'
            value={this.state.stepPromptIvr}
            onChange={e => this.stepPromptIvrChange(e)}
            onBlur={e => this.stepPromptIvrSubmit(e)} />
          <label htmlFor='step_editor_voice_message' className={classNames({'active': this.state.stepPromptIvr})}>Voice message</label>
        </div>
      </div>

      ivrFileInput = <div className='row audio-section'>
        <ConfirmationModal modalId='invalidTypeFile' modalText='The system only accepts MPEG and WAV files' header='Invalid file type' confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '600px'}} />
        <ConfirmationModal modalId='unprocessableEntity' header='Invalid file' modalText={this.state.audioErrors} confirmationText='accept' onConfirm={(event) => event.preventDefault()} style={{maxWidth: '600px'}} />
        <div className='audio-dropdown'>
          <Dropdown className='step-mode underlined' label={this.state.audioSource == 'tts' ? <span className='v-middle'><i className='material-icons'>record_voice_over</i> Text to speech</span> : <span><i className='material-icons'>file_upload</i> Upload a file</span>} constrainWidth={false} dataBelowOrigin={false}>
            <DropdownItem>
              <a onClick={e => this.changeIvrMode(e, 'tts')}>
                <i className='material-icons left'>record_voice_over</i>
                Text to speech
                {this.state.audioSource == 'tts' ? <i className='material-icons right'>done</i> : ''}
              </a>
            </DropdownItem>
            <DropdownItem>
              <a onClick={e => this.changeIvrMode(e, 'upload')}>
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
            <source src={this.state.audioSrc} type='audio/mpeg' />
          </audio>
          <AudioDropzone onDrop={files => this.handleFileUpload(files)} onDropRejected={() => $('#invalidTypeFile').modal('open')} />
        </div>
        : ''}
      </div>

      ivrInput = <div className='row'>
        {ivrTextInput}
        {ivrFileInput}
      </div>
    }

    return (
      <Card key={step.id}>
        <ul className='collection collection-card'>
          <li className='collection-item input-field header'>
            <div className='row'>
              <div className='col s12'>
                <div className='left'>
                  <Dropdown className='step-mode' label={this.state.stepType == 'multiple-choice' ? <i className='material-icons'>list</i> : <i className='material-icons sharp'>dialpad</i>} constrainWidth={false} dataBelowOrigin={false}>
                    <DropdownItem>
                      <a onClick={e => this.changeStepType('multiple-choice')}>
                        <i className='material-icons left'>list</i>
                        Multiple choice
                        {this.state.stepType == 'multiple-choice' ? <i className='material-icons right'>done</i> : ''}
                      </a>
                    </DropdownItem>
                    <DropdownItem>
                      <a onClick={e => this.changeStepType('numeric')}>
                        <i className='material-icons left sharp'>dialpad</i>
                        Numeric
                        {this.state.stepType == 'numeric' ? <i className='material-icons right'>done</i> : ''}
                      </a>
                    </DropdownItem>
                  </Dropdown>
                </div>
                <EditableTitleLabel className='editable-field' title={this.state.stepTitle} onSubmit={(value) => { this.stepTitleSubmit(value) }} />
                <a href='#!'
                  className='collapse right'
                  onClick={e => {
                    e.preventDefault()
                    onCollapse()
                  }}>
                  <i className='material-icons'>expand_less</i>
                </a>
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div className='row'>
              <div className='col s12'>
                <h5>Question Prompt</h5>
              </div>
            </div>
            {smsInput}
            {ivrTextInput}
            {ivrFileInput}
          </li>
          <li className='collection-item'>
            <div className='row'>
              <div className='col s12'>
                {editor}
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div className='row'>
              <div className='col s12'>
                Variable name:
                <div className='input-field inline'>
                  <input
                    type='text'
                    value={this.state.stepStore}
                    onChange={e => this.stepStoreChange(e)}
                    onBlur={e => this.stepStoreSubmit(e)}
                    />
                </div>
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div className='row'>
              <a href='#!'
                className='right'
                onClick={(e) => this.delete(e)}>
                DELETE
              </a>
            </div>
          </li>
        </ul>
      </Card>
    )
  }
}

StepEditor.propTypes = {
  questionnaireActions: PropTypes.object.isRequired,
  dispatch: PropTypes.func,
  questionnaire: PropTypes.object.isRequired,
  step: PropTypes.object.isRequired,
  onCollapse: PropTypes.func.isRequired,
  onDelete: PropTypes.func.isRequired,
  skip: PropTypes.array.isRequired
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(StepEditor)
