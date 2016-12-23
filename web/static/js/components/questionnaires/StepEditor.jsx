// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { Dropdown, DropdownItem } from '../ui'
import * as questionnaireActions from '../../actions/questionnaire'
import StepMultipleChoiceEditor from './StepMultipleChoiceEditor'
import SmsPrompt from './SmsPrompt'
import IvrPrompt from './IvrPrompt'
import StepCard from './StepCard'
import StepNumericEditor from './StepNumericEditor'
import StepLanguageSelection from './StepLanguageSelection'
import { createAudio, autocompleteVars } from '../../api.js'
import DraggableStep from './DraggableStep'

type Props = {
  step: Step,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  project: any,
  errors: any,
  errorPath: string,
  stepsAfter: Step[],
  draggable: boolean
};

type State = {
  stepTitle: string,
  stepType: string,
  stepPromptSms: string,
  stepPromptIvr: string,
  stepStore: string,
  audioErrors: string,
  audioId: any,
  audioSource: string,
  audioUri: string,
};

class StepEditor extends Component {
  props: Props
  state: State
  clickedVarAutocomplete: boolean

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
    this.clickedVarAutocomplete = false
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

  stepStoreChange(e, value) {
    if (this.clickedVarAutocomplete) return
    if (e) e.preventDefault()
    this.setState({stepStore: value})
  }

  stepStoreSubmit(e, value) {
    if (this.clickedVarAutocomplete) return
    const varsDropdown = this.refs.varsDropdown
    $(varsDropdown).hide()

    if (e) e.preventDefault()
    const { step } = this.props
    this.props.questionnaireActions.changeStepStore(step.id, value)
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
    const lang = props.questionnaire.defaultLanguage

    let audioId = null
    if (step.prompt[lang] && step.prompt[lang].ivr) {
      let ivrPrompt: AudioPrompt = step.prompt[lang].ivr
      if (ivrPrompt.audioSource === 'upload') {
        audioId = ivrPrompt.audioId
      }
    }

    return {
      stepTitle: step.title,
      stepType: step.type,
      stepPromptSms: (step.prompt[lang] || {}).sms || '',
      stepPromptIvr: ((step.prompt[lang] || {}).ivr || {}).text || '',
      stepStore: step.store || '',
      audioId: audioId,
      audioSource: ((step.prompt[lang] || {}).ivr || {}).audioSource || 'tts',
      audioUri: (step.prompt[lang] && step.prompt[lang].ivr && step.prompt[lang].ivr.audioId ? `/api/v1/audios/${step.prompt[lang].ivr.audioId}` : ''),
      audioErrors: ''
    }
  }

  handleFileUpload(files) {
    const { step } = this.props
    createAudio(files)
      .then(response => {
        this.setState({audioUri: `/api/v1/audios/${response.result}`}, () => {
          this.props.questionnaireActions.changeStepAudioIdIvr(step.id, response.result)
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

  clickedVarAutocompleteCallback(e) {
    this.clickedVarAutocomplete = true
  }

  render() {
    const { step, onCollapse, questionnaire, errors, errorPath, stepsAfter } = this.props

    const sms = questionnaire.modes.indexOf('sms') != -1
    const ivr = questionnaire.modes.indexOf('ivr') != -1

    let editor
    if (step.type == 'multiple-choice') {
      editor = <StepMultipleChoiceEditor questionnaire={questionnaire} step={step} stepsAfter={stepsAfter} sms={sms} ivr={ivr} errors={errors} errorPath={errorPath} />
    } else if (step.type == 'numeric') {
      editor = <StepNumericEditor questionnaire={questionnaire} step={step} stepsAfter={stepsAfter} />
    } else if (step.type == 'language-selection') {
      editor = <StepLanguageSelection step={step} />
    } else {
      throw new Error(`unknown step type: ${step.type}`)
    }

    let smsInput = null
    if (sms) {
      // TODO: uncomment line below once error styles are fixed
      let smsInputErrors = null // errors[`${errorPath}.prompt.sms`]
      smsInput = <SmsPrompt id='step_editor_sms_prompt' value={this.state.stepPromptSms} inputErrors={smsInputErrors} onChange={e => this.stepPromptSmsChange(e)} onBlur={e => this.stepPromptSmsSubmit(e)} />
    }

    let ivrInput = null
    if (ivr) {
      // TODO: uncomment line below once error styles are fixed
      let ivrInputErrors = null // errors[`${errorPath}.prompt.ivr.text`]
      ivrInput = <IvrPrompt id='step_editor_sms_prompt' value={this.state.stepPromptIvr} inputErrors={ivrInputErrors} onChange={e => this.stepPromptIvrChange(e)} onBlur={e => this.stepPromptIvrSubmit(e)} changeIvrMode={(e, mode) => this.changeIvrMode(e, mode)} audioErrors={this.state.audioErrors} audioSource={this.state.audioSource} audioUri={this.state.audioUri} handleFileUpload={files => this.handleFileUpload(files)} />
    }

    let prompts = <li className='collection-item' key='prompts'>
      <div className='row'>
        <div className='col s12'>
          <h5>Question Prompt</h5>
        </div>
      </div>
      {smsInput}
      {ivrInput}
    </li>

    let optionsEditor = <li className='collection-item' key='editor'>
      <div className='row'>
        <div className='col s12'>
          {editor}
        </div>
      </div>
    </li>

    let variableName = <li className='collection-item' key='variable_name'>
      <div className='row'>
        <div className='col s12'>
          Variable name:
          <div className='input-field inline'>
            <input
              type='text'
              value={this.state.stepStore}
              onChange={e => this.stepStoreChange(e, e.target.value)}
              onBlur={e => this.stepStoreSubmit(e, e.target.value)}
              autoComplete='off'
              className='autocomplete'
              ref='varInput'
            />
            <ul className='autocomplete-content dropdown-content var-dropdown'
              ref='varsDropdown'
              onMouseDown={(e) => this.clickedVarAutocompleteCallback(e)}
            />
          </div>
        </div>
      </div>
    </li>

    let deleteButton = <li className='collection-item' key='delete_button'>
      <div className='row'>
        <a href='#!'
          className='right'
          onClick={(e) => this.delete(e)}>
          DELETE
        </a>
      </div>
    </li>

    let items = [prompts, optionsEditor, variableName, deleteButton]

    let icon = null
    if (this.state.stepType != 'language-selection') {
      icon = <div className='left'>
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
    } else {
      icon = <i className='material-icons left'>language</i>
    }

    return (
      <DraggableStep step={step}>
        <StepCard onCollapse={onCollapse} items={items} icon={icon} step={step} stepTitle={this.state.stepTitle} onTitleSubmit={(value) => { this.stepTitleSubmit(value) }} />
      </DraggableStep>
    )
  }

  componentDidMount() {
    this.setupAutocomplete()
  }

  componentDidUpdate() {
    this.setupAutocomplete()
  }

  setupAutocomplete() {
    const self = this
    const varInput = this.refs.varInput
    const varsDropdown = this.refs.varsDropdown
    const { project } = this.props

    $(varInput).click(() => $(varsDropdown).show())

    $(varInput).materialize_autocomplete({
      limit: 100,
      multiple: {
        enable: false
      },
      dropdown: {
        el: varsDropdown,
        itemTemplate: '<li class="ac-item" data-id="<%= item.id %>" data-text=\'<%= item.text %>\'><%= item.text %></li>'
      },
      onSelect: (item) => {
        self.clickedVarAutocomplete = false
        self.stepStoreChange(null, item.text)
        self.stepStoreSubmit(null, item.text)
      },
      getData: (value, callback) => {
        autocompleteVars(project.id, value)
        .then(response => {
          callback(value, response.map(x => ({id: x, text: x})))
        })
      }
    })
  }
}

const mapStateToProps = (state, ownProps) => ({
  project: state.project.data,
  questionnaire: state.questionnaire.data,
  errors: state.questionnaire.errors
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(StepEditor)
