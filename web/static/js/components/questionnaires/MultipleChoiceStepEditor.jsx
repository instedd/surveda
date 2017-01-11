// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import StepTypeSelector from './StepTypeSelector'
import * as questionnaireActions from '../../actions/questionnaire'
import StepMultipleChoiceEditor from './StepMultipleChoiceEditor'
import StepPrompts from './StepPrompts'
import StepCard from './StepCard'
import DraggableStep from './DraggableStep'
import StepDeleteButton from './StepDeleteButton'
import StepStoreVariable from './StepStoreVariable'
import { getStepPromptSms, getStepPromptIvrText } from '../../step'

type Props = {
  step: MultipleChoiceStep,
  stepIndex: number,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  readOnly: boolean,
  errors: Errors,
  stepsAfter: Step[],
  stepsBefore: Step[]
};

type State = {
  stepTitle: string,
  stepType: string,
  stepPromptSms: string,
  stepPromptIvr: string
};

class MultipleChoiceStepEditor extends Component {
  props: Props
  state: State

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { step, questionnaire } = props
    const lang = questionnaire.activeLanguage

    return {
      stepTitle: step.title,
      stepType: step.type,
      stepPromptSms: getStepPromptSms(step, lang),
      stepPromptIvr: getStepPromptIvrText(step, lang)
    }
  }

  render() {
    const { step, stepIndex, onCollapse, questionnaire, readOnly, errors, stepsAfter, stepsBefore, onDelete } = this.props

    return (
      <DraggableStep step={step} readOnly={readOnly}>
        <StepCard onCollapse={onCollapse} stepId={step.id} stepTitle={this.state.stepTitle}
          icon={
            <StepTypeSelector stepType={step.type} stepId={step.id} />
          } >
          <StepPrompts
            step={step}
            stepIndex={stepIndex}
            errors={errors} />
          <li className='collection-item' key='editor'>
            <div className='row'>
              <div className='col s12'>
                <StepMultipleChoiceEditor
                  questionnaire={questionnaire}
                  step={step}
                  stepIndex={stepIndex}
                  stepsAfter={stepsAfter}
                  stepsBefore={stepsBefore}
                  readOnly={readOnly}
                  errors={errors} />
              </div>
            </div>
          </li>
          <StepStoreVariable step={step} readOnly={readOnly} />
          {readOnly ? null : <StepDeleteButton onDelete={onDelete} /> }
        </StepCard>
      </DraggableStep>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data,
  readOnly: state.project && state.project.data ? state.project.data.readOnly : true
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(MultipleChoiceStepEditor)
