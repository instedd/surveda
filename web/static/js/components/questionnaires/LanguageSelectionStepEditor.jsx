// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import StepPrompts from './StepPrompts'
import StepCard from './StepCard'
import StepLanguageSelection from './StepLanguageSelection'
import DraggableStep from './DraggableStep'
import StepStoreVariable from './StepStoreVariable'
import { getStepPromptSms, getStepPromptIvrText } from '../../step'

type Props = {
  step: LanguageSelectionStep,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  errors: any,
  errorPath: string
};

type State = {
  stepTitle: string,
  stepType: string,
  stepPromptSms: string,
  stepPromptIvr: string
};

class LanguageSelectionStepEditor extends Component {
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

    return {
      stepTitle: step.title,
      stepType: step.type,
      stepPromptSms: getStepPromptSms(step, questionnaire.defaultLanguage),
      stepPromptIvr: getStepPromptIvrText(step, questionnaire.defaultLanguage)
    }
  }

  render() {
    const { step, onCollapse, errors, errorPath } = this.props

    return (
      <DraggableStep step={step}>
        <StepCard onCollapse={onCollapse} stepId={step.id} stepTitle={this.state.stepTitle} icon={<i className='material-icons left'>language</i>} >
          <StepPrompts
            step={step}
            errors={errors}
            errorPath={errorPath} />
          <li className='collection-item' key='editor'>
            <div className='row'>
              <div className='col s12'>
                <StepLanguageSelection step={step} />
              </div>
            </div>
          </li>
          <StepStoreVariable step={step} />
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

export default connect(mapStateToProps, mapDispatchToProps)(LanguageSelectionStepEditor)
