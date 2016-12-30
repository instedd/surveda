// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import StepTypeSelector from './StepTypeSelector'
import * as questionnaireActions from '../../actions/questionnaire'
import StepPrompts from './StepPrompts'
import StepCard from './StepCard'
import StepNumericEditor from './StepNumericEditor'
import DraggableStep from './DraggableStep'
import StepDeleteButton from './StepDeleteButton'
import StepStoreVariable from './StepStoreVariable'
import { getStepPromptSms, getStepPromptIvrText } from '../../step'

type Props = {
  step: NumericStep,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  errors: any,
  errorPath: string,
  stepsAfter: Step[],
  stepsBefore: Step[]
};

type State = {
  stepTitle: string,
  stepType: string,
  stepPromptSms: string,
  stepPromptIvr: string
};

class NumericStepEditor extends Component {
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
    const { step } = props
    const lang = props.questionnaire.activeLanguage

    return {
      stepTitle: step.title,
      stepType: step.type,
      stepPromptSms: getStepPromptSms(step, lang),
      stepPromptIvr: getStepPromptIvrText(step, lang)
    }
  }

  render() {
    const { step, onCollapse, questionnaire, stepsAfter, stepsBefore, onDelete, errors, errorPath } = this.props

    return (
      <DraggableStep step={step}>
        <StepCard onCollapse={onCollapse} stepId={step.id} stepTitle={this.state.stepTitle} icon={<StepTypeSelector stepType={step.type} stepId={step.id} />} >
          <StepPrompts
            step={step}
            errors={errors}
            errorPath={errorPath} />
          <li className='collection-item' key='editor'>
            <div className='row'>
              <div className='col s12'>
                <StepNumericEditor
                  questionnaire={questionnaire}
                  step={step}
                  stepsAfter={stepsAfter}
                  stepsBefore={stepsBefore} />
              </div>
            </div>
          </li>
          <StepStoreVariable step={step} />
          <StepDeleteButton onDelete={onDelete} />
        </StepCard>
      </DraggableStep>
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

export default connect(mapStateToProps, mapDispatchToProps)(NumericStepEditor)
