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
    const { step, stepIndex, onCollapse, questionnaire, readOnly, stepsAfter, stepsBefore, onDelete, errors } = this.props

    return (
      <DraggableStep step={step}>
        <StepCard onCollapse={onCollapse} readOnly={readOnly} stepId={step.id} stepTitle={this.state.stepTitle} icon={<StepTypeSelector stepType={step.type} readOnly={readOnly} stepId={step.id} />} >
          <StepPrompts
            step={step}
            readOnly={readOnly}
            stepIndex={stepIndex}
            errors={errors} />
          <li className='collection-item' key='editor'>
            <div className='row'>
              <div className='col s12'>
                <StepNumericEditor
                  questionnaire={questionnaire}
                  readOnly={readOnly}
                  step={step}
                  stepsAfter={stepsAfter}
                  stepsBefore={stepsBefore} />
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
  questionnaire: state.questionnaire.data
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(NumericStepEditor)
