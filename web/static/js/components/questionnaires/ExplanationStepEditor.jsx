// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import StepTypeSelector from './StepTypeSelector'
import * as questionnaireActions from '../../actions/questionnaire'
import StepPrompts from './StepPrompts'
import StepCard from './StepCard'
import DraggableStep from './DraggableStep'
import StepDeleteButton from './StepDeleteButton'
import SkipLogic from './SkipLogic'

type Props = {
  step: ExplanationStep,
  stepIndex: number,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  errors: Errors,
  readOnly: boolean,
  stepsAfter: Step[],
  stepsBefore: Step[]
};

type State = {
  stepTitle: string,
  stepType: string,
  stepPromptSms: string,
  stepPromptIvr: string,
  skipLogic: ?string
};

class ExplanationStepEditor extends Component {
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
    const lang = props.questionnaire.defaultLanguage

    return {
      stepTitle: step.title,
      stepType: step.type,
      stepPromptSms: (step.prompt[lang] || {}).sms || '',
      stepPromptIvr: ((step.prompt[lang] || {}).ivr || {}).text || '',
      skipLogic: step.skipLogic
    }
  }

  skipLogicChange(skipOption, rangeIndex) {
    const { questionnaireActions, step } = this.props

    this.setState({ skipLogic: skipOption }, () => {
      questionnaireActions.changeExplanationStepSkipLogic(step.id, skipOption)
    })
  }

  render() {
    const { step, stepIndex, onCollapse, stepsAfter, stepsBefore, onDelete, errors, readOnly } = this.props

    return (
      <DraggableStep step={step}>
        <StepCard onCollapse={onCollapse} stepId={step.id} stepTitle={this.state.stepTitle} icon={<StepTypeSelector stepType={step.type} stepId={step.id} />} >
          <StepPrompts
            step={step}
            stepIndex={stepIndex}
            errors={errors}
            classes='no-separator'
          />
          <li className='collection-item' key='editor'>
            <div className='row'>
              <div className='col s6'>
                <SkipLogic
                  onChange={skipOption => this.skipLogicChange(skipOption)}
                  readOnly={readOnly}
                  value={step.skipLogic}
                  stepsAfter={stepsAfter}
                  stepsBefore={stepsBefore}
                  label='Skip logic'
                />
              </div>
            </div>
          </li>
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

export default connect(mapStateToProps, mapDispatchToProps)(ExplanationStepEditor)
