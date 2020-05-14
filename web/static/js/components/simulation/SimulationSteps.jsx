// @flow
import React, { Component } from 'react'
import { icon } from '../../step'
import { translate } from 'react-i18next'
import { Card, UntitledIfEmpty } from '../ui'
import classNames from 'classnames/bind'
import { flatMapDepth } from 'lodash'
import propsAreEqual from '../../propsAreEqual'

type Step = {
  type: string,
  title: string,
  id: string,
  steps: ?Array<Step>
}

type Submission = {
  stepId: string,
  response: ?string
}

type Props = {
  submissions: Array<Submission>,
  steps: Array<Step>,
  currentStepId: string,
  t: Function
}

type State = {
  headedBySectionSteps: Array<Step>
}

const SimulationSteps = translate()(class extends Component<Props, State> {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  componentWillReceiveProps(newProps) {
    if (propsAreEqual(this.props, newProps)) return
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { steps } = props
    return {
      headedBySectionSteps: flatMapDepth(steps, step => {
        if (step.type == 'section') {
          return [
            step,
            step.steps
          ]
        } else {
          return step
        }
      }, 2)
    }
  }

  isActive = (stepId: string): boolean => {
    const { currentStepId } = this.props
    return currentStepId == stepId
  }

  isCompleted = (stepId: string): boolean => {
    if (this.isActive(stepId)) return false
    const { submissions } = this.props
    return submissions.some(submission => submission.stepId == stepId)
  }

  wasSkipped = (stepId: string): boolean => {
    if (this.isActive(stepId) || this.isCompleted(stepId)) return false
    const { currentStepId } = this.props
    if (currentStepId) {
      const { headedBySectionSteps } = this.state
      return headedBySectionSteps.findIndex(step => step.id == stepId) < headedBySectionSteps.findIndex(step => step.id == currentStepId)
    } else {
      return true
    }
  }

  render() {
    const { headedBySectionSteps } = this.state
    return <Card>
      <ul className='collection simulation'>
        {
          headedBySectionSteps.map((step, index) => <StepItem
            stepType={step.type}
            title={step.title}
            active={this.isActive(step.id)}
            completed={this.isCompleted(step.id)}
            skipped={this.wasSkipped(step.id)}
            key={`step-item-${index}`}
          />)
        }
      </ul>
    </Card>
  }
})

type StepItemProps = {
  stepType: string,
  title: string,
  response: ?string,
  active: ?boolean,
  completed: ?boolean,
  skipped: ?boolean,
  t: Function
}

const StepItem = translate()(class extends Component<StepItemProps> {
  render() {
    const { stepType, title, response, active, completed, skipped, t } = this.props
    const isSection = stepType == 'section'
    return <li className={classNames('collection-item', { done: completed, skipped, active, section: isSection })}>
      <i className='material-icons left sharp'>{completed ? 'check_circle' : icon(stepType)}</i>
      <UntitledIfEmpty className='title' text={title} emptyText={isSection ? t('Untitled section') : t('Untitled question')} />
      <br />
      <span className='value'>{response}</span>
    </li>
  }
})

export default SimulationSteps
