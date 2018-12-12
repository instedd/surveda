// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import MultipleChoiceStepEditor from './MultipleChoiceStepEditor'
import NumericStepEditor from './NumericStepEditor'
import LanguageSelectionStepEditor from './LanguageSelectionStepEditor'
import ExplanationStepEditor from './ExplanationStepEditor'
import FlagStepEditor from './FlagStepEditor'

type Props = {
  step: Step,
  stepIndex: number,
  errorPath: string,
  errorsByPath: ErrorsByPath,
  questionnaireActions: any,
  readOnly: boolean,
  quotaCompletedSteps: boolean,
  onDelete: Function,
  onCollapse: Function,
  stepsAfter: Step[],
  stepsBefore: Step[],
  isNew: boolean
};

class StepEditor extends Component<Props> {
  clickedVarAutocomplete: boolean

  // Remember last step shown (expanded)
  lastStepId: any

  // Whenever the component is rendered (or re-rendered)
  // we scroll to the step if it changed from the last time
  // we checked.
  componentDidMount() {
    this.scrollIfNeeded()
  }

  componentDidUpdate() {
    this.scrollIfNeeded()
  }

  componentWillUnmount() {
    this.lastStepId = null
  }

  scrollIfNeeded() {
    const { step } = this.props
    if (step.id != this.lastStepId) {
      const elem = $(`#step-id-${step.id}`)
      if (elem.length > 0) {
        $('html, body').animate({scrollTop: elem.offset().top}, 500)
      }
    }
    this.lastStepId = step.id
  }

  render() {
    const {step, ...commonProps} = this.props

    switch (step.type) {
      case 'multiple-choice':
        return <MultipleChoiceStepEditor {...commonProps} step={step} />
      case 'numeric':
        return <NumericStepEditor {...commonProps} step={step} />
      case 'explanation':
        return <ExplanationStepEditor {...commonProps} step={step} />
      case 'flag':
        return <FlagStepEditor {...commonProps} step={step} />
      case 'language-selection':
        return <LanguageSelectionStepEditor {...commonProps} step={step} />
      default:
        throw new Error(`unknown step type: ${step.type}`)
    }
  }
}

const mapStateToProps = (state, ownProps) => ({
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(StepEditor)
