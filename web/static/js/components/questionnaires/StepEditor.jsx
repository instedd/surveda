// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import MultipleChoiceStepEditor from './MultipleChoiceStepEditor'
import NumericStepEditor from './NumericStepEditor'
import LanguageSelectionStepEditor from './LanguageSelectionStepEditor'

type Props = {
  step: Step,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  errors: any,
  errorPath: string,
  stepsAfter: Step[],
  stepsBefore: Step[]
};

class StepEditor extends Component {
  props: Props
  clickedVarAutocomplete: boolean

  render() {
    const { step, questionnaire, errors, errorPath, stepsAfter, stepsBefore, onCollapse, onDelete } = this.props

    let editor

    let commonProps = {step, questionnaireActions, onCollapse, questionnaire, errors, errorPath}

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
  questionnaire: state.questionnaire.data,
  errors: state.questionnaire.errors
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(StepEditor)
