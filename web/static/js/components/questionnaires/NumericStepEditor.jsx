// @flow
import React, { Component } from "react"
import { bindActionCreators } from "redux"
import { connect } from "react-redux"
import StepTypeSelector from "./StepTypeSelector"
import * as questionnaireActions from "../../actions/questionnaire"
import StepPrompts from "./StepPrompts"
import StepCard from "./StepCard"
import StepNumericEditor from "./StepNumericEditor"
import StepDeleteButton from "./StepDeleteButton"
import StepStoreVariable from "./StepStoreVariable"
import propsAreEqual from "../../propsAreEqual"
import withQuestionnaire from "./withQuestionnaire"

type Props = {
  step: NumericStep,
  stepIndex: number,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  readOnly: boolean,
  quotaCompletedSteps: boolean,
  errorPath: string,
  errorsByPath: ErrorsByPath,
  stepsAfter: Step[],
  stepsBefore: Step[],
  isNew: boolean,
}

type State = {
  stepTitle: string,
}

class NumericStepEditor extends Component<Props, State> {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  componentWillReceiveProps(newProps) {
    if (propsAreEqual(this.props, newProps)) return

    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { step } = props

    return {
      stepTitle: step.title,
    }
  }

  render() {
    const {
      step,
      stepIndex,
      onCollapse,
      questionnaire,
      readOnly,
      quotaCompletedSteps,
      stepsAfter,
      stepsBefore,
      onDelete,
      errorPath,
      errorsByPath,
      isNew,
    } = this.props

    return (
      <StepCard
        onCollapse={onCollapse}
        readOnly={readOnly}
        stepId={step.id}
        stepTitle={this.state.stepTitle}
        stepType={step.type}
        relevant={step.relevant}
        icon={
          <StepTypeSelector
            stepType={step.type}
            readOnly={readOnly}
            quotaCompletedSteps={quotaCompletedSteps}
            stepId={step.id}
          />
        }
      >
        <StepPrompts
          step={step}
          readOnly={readOnly}
          stepIndex={stepIndex}
          errorPath={errorPath}
          errorsByPath={errorsByPath}
          isNew={isNew}
        />
        <li className="collection-item" key="editor">
          <div className="row">
            <div className="col s12">
              <StepNumericEditor
                questionnaire={questionnaire}
                readOnly={readOnly}
                step={step}
                stepIndex={stepIndex}
                stepsAfter={stepsAfter}
                stepsBefore={stepsBefore}
                errorPath={errorPath}
                errorsByPath={errorsByPath}
                isNew={isNew}
              />
            </div>
          </div>
        </li>
        <StepStoreVariable
          step={step}
          readOnly={readOnly}
          errorPath={errorPath}
          errorsByPath={errorsByPath}
        />
        {readOnly ? null : <StepDeleteButton onDelete={onDelete} />}
      </StepCard>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
})

export default connect(null, mapDispatchToProps)(withQuestionnaire(NumericStepEditor))
