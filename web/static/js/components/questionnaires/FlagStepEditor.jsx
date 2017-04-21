// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import StepTypeSelector from './StepTypeSelector'
import * as questionnaireActions from '../../actions/questionnaire'
import StepCard from './StepCard'
import DraggableStep from './DraggableStep'
import StepDeleteButton from './StepDeleteButton'
import SkipLogic from './SkipLogic'
import propsAreEqual from '../../propsAreEqual'

type Props = {
  step: FlagStep,
  stepIndex: number,
  questionnaireActions: any,
  onDelete: Function,
  onCollapse: Function,
  questionnaire: Questionnaire,
  errorPath: string,
  errorsByPath: ErrorsByPath,
  readOnly: boolean,
  stepsAfter: Step[],
  stepsBefore: Step[]
};

type State = {
  stepTitle: string,
  stepType: string,
  disposition: 'completed' | 'partial' | 'ineligible' | 'refused',
  skipLogic: ?string
};

class FlagStepEditor extends Component {
  props: Props
  state: State

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
      stepType: step.type,
      disposition: step.disposition,
      skipLogic: step.skipLogic
    }
  }

  skipLogicChange(skipOption, rangeIndex) {
    const { questionnaireActions, step } = this.props

    this.setState({ skipLogic: skipOption }, () => {
      questionnaireActions.changeExplanationStepSkipLogic(step.id, skipOption)
    })
  }

  dispositionChange(disposition, rangeIndex) {
    const { questionnaireActions, step } = this.props

    this.setState({ disposition: disposition }, () => {
      questionnaireActions.changeDisposition(step.id, disposition)
    })
  }

  render() {
    const { step, onCollapse, stepsAfter, stepsBefore, onDelete, readOnly } = this.props

    return (
      <DraggableStep step={step} readOnly={readOnly}>
        <StepCard onCollapse={onCollapse} readOnly={readOnly} stepId={step.id} stepTitle={this.state.stepTitle} icon={<StepTypeSelector stepType={step.type} stepId={step.id} readOnly={readOnly} />} >
          <li className='collection-item' key='dispositions'>
            <h5>Disposition</h5>
            <p><b>Choose the disposition you want to set at this point of the questionnaire.</b></p>
            <div className='row'>
              <div className='col s6'>
                <p>
                  <input
                    id={`${step.id}_disposition_partial`}
                    type='radio'
                    name='questionnaire_disposition'
                    className='with-gap'
                    value='partial'
                    checked={this.state.disposition == 'partial'}
                    onChange={e => this.dispositionChange('partial')}
                    disabled={readOnly}
                  />
                  <label htmlFor={`${step.id}_disposition_partial`}>Partial</label>
                </p>
                <p>
                  <input
                    id={`${step.id}_disposition_ineligible`}
                    type='radio'
                    name='questionnaire_disposition'
                    className='with-gap'
                    value='ineligible'
                    checked={this.state.disposition == 'ineligible'}
                    onChange={e => this.dispositionChange('ineligible')}
                    disabled={readOnly}
                  />
                  <label htmlFor={`${step.id}_disposition_ineligible`}>Ineligible</label>
                </p>
                <p>
                  <input
                    id={`${step.id}_disposition_refused`}
                    type='radio'
                    name='questionnaire_disposition'
                    className='with-gap'
                    value='refused'
                    checked={this.state.disposition == 'refused'}
                    onChange={e => this.dispositionChange('refused')}
                    disabled={readOnly}
                  />
                  <label htmlFor={`${step.id}_disposition_refused`}>Refused</label>
                </p>
                <p>
                  <input
                    id={`${step.id}_disposition_completed`}
                    type='radio'
                    name='questionnaire_disposition'
                    className='with-gap'
                    value='completed'
                    checked={this.state.disposition == 'completed'}
                    onChange={e => this.dispositionChange('completed')}
                    disabled={readOnly}
                  />
                  <label htmlFor={`${step.id}_disposition_completed`}>Completed</label>
                </p>
              </div>
            </div>
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
  questionnaire: state.questionnaire.data
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(FlagStepEditor)
