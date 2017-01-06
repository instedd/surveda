// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import MultipleChoiceStepEditor from './MultipleChoiceStepEditor'
import NumericStepEditor from './NumericStepEditor'
import LanguageSelectionStepEditor from './LanguageSelectionStepEditor'
import ExplanationStepEditor from './ExplanationStepEditor'
import { errorsByLang, stepPath } from '../../questionnaireErrors'

type Props = {
  step: Step,
  stepIndex: number,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  errors: QuizErrors,
  errorPath: string,
  stepsAfter: Step[],
  stepsBefore: Step[]
};

class StepEditor extends Component {
  props: Props
  clickedVarAutocomplete: boolean

  render() {
    const { step, stepIndex, errors, stepsAfter, stepsBefore, onCollapse, onDelete } = this.props

    let editor

    let commonProps = {step, stepIndex, questionnaireActions, onCollapse, errors}

    if (step.type == 'multiple-choice') {
      editor =
        <MultipleChoiceStepEditor
          {...commonProps}
          onDelete={onDelete}
          stepsAfter={stepsAfter}
          stepsBefore={stepsBefore} />
    } else if (step.type == 'numeric') {
      editor =
        <NumericStepEditor
          {...commonProps}
          onDelete={onDelete}
          stepsAfter={stepsAfter}
          stepsBefore={stepsBefore} />
    } else if (step.type == 'explanation') {
      editor =
        <ExplanationStepEditor
          {...commonProps}
          stepsAfter={stepsAfter}
          stepsBefore={stepsBefore} />
    } else if (step.type == 'language-selection') {
      editor =
        <LanguageSelectionStepEditor
          {...commonProps} />
    } else {
      throw new Error(`unknown step type: ${step.type}`)
    }

    return (
      editor
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  errors: errorsByLang(state.questionnaire)[state.questionnaire.data.activeLanguage],
  errorPath: stepPath(ownProps.stepIndex)
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(StepEditor)
