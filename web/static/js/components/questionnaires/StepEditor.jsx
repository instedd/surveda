// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import MultipleChoiceStepEditor from './MultipleChoiceStepEditor'
import NumericStepEditor from './NumericStepEditor'
import LanguageSelectionStepEditor from './LanguageSelectionStepEditor'
import ExplanationStepEditor from './ExplanationStepEditor'
import { errorsByLang } from '../../questionnaireErrors'

type Props = {
  step: Step,
  stepIndex: number,
  questionnaireActions: any,
  readOnly: boolean,
  onDelete: Function,
  onCollapse: Function,
  errors: Errors,
  stepsAfter: Step[],
  stepsBefore: Step[]
};

class StepEditor extends Component {
  props: Props
  clickedVarAutocomplete: boolean

  render() {
    const {step, ...commonProps} = this.props

    switch (step.type) {
      case 'multiple-choice':
        return <MultipleChoiceStepEditor {...commonProps} step={step} />
      case 'numeric':
        return <NumericStepEditor {...commonProps} step={step} />
      case 'explanation':
        return <ExplanationStepEditor {...commonProps} step={step} />
      case 'language-selection':
        return <LanguageSelectionStepEditor {...commonProps} step={step} />
      default:
        throw new Error(`unknown step type: ${step.type}`)
    }
  }
}

const mapStateToProps = (state, ownProps) => ({
  errors: ownProps.isNew ? {} : errorsByLang(state.questionnaire)[state.questionnaire.data.activeLanguage]
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(StepEditor)
