// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import MultipleChoiceStepEditor from './MultipleChoiceStepEditor'
import NumericStepEditor from './NumericStepEditor'
import LanguageSelectionStepEditor from './LanguageSelectionStepEditor'
import { autocompleteVars } from '../../api.js'

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
  stepsBefore: Step[]
};

type State = {
  stepTitle: string,
  stepType: string,
  stepPromptSms: string,
  stepPromptIvr: string,
  stepStore: string
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

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { step } = props
    const lang = props.questionnaire.defaultLanguage

    return {
      stepTitle: step.title,
      stepType: step.type,
      stepPromptSms: (step.prompt[lang] || {}).sms || '',
      stepPromptIvr: ((step.prompt[lang] || {}).ivr || {}).text || '',
      stepStore: step.store || ''
    }
  }

  clickedVarAutocompleteCallback(e) {
    this.clickedVarAutocomplete = true
  }

  render() {
    const { step, questionnaire, errors, errorPath, stepsAfter, stepsBefore, onCollapse, project, onDelete } = this.props

    let editor
    if (step.type == 'multiple-choice') {
      editor =
        <MultipleChoiceStepEditor
          step={step}
          questionnaireActions={questionnaireActions}
          onDelete={onDelete}
          onCollapse={onCollapse}
          questionnaire={questionnaire}
          project={project}
          errors={errors}
          errorPath={errorPath}
          stepsAfter={stepsAfter}
          stepsBefore={stepsBefore} />
    } else if (step.type == 'numeric') {
      editor =
        <NumericStepEditor
          step={step}
          questionnaireActions={questionnaireActions}
          onDelete={onDelete}
          onCollapse={onCollapse}
          questionnaire={questionnaire}
          project={project}
          errors={errors}
          errorPath={errorPath}
          stepsAfter={stepsAfter}
          stepsBefore={stepsBefore} />
    } else if (step.type == 'language-selection') {
      editor =
        <LanguageSelectionStepEditor
          step={step}
          questionnaireActions={questionnaireActions}
          onCollapse={onCollapse}
          questionnaire={questionnaire}
          project={project}
          errors={errors}
          errorPath={errorPath}
          stepsAfter={stepsAfter}
          stepsBefore={stepsBefore} />
    } else {
      throw new Error(`unknown step type: ${step.type}`)
    }

    return (
      editor
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
