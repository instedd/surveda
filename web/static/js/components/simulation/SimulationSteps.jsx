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
  steps: ?Array<Step>,
  status: string,
  response: ?string
}

type Submission = {
  stepId: string,
  response: ?string
}

type Props = {
  submissions: Array<Submission>,
  steps: Array<Step>,
  currentStepId: string,
  t: Function,
  simulationIsEnded: boolean
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
    const { steps, submissions, simulationIsEnded, currentStepId } = props

    const isActive = (step: Step): boolean => {
      return step.type == 'section'
        ? !!step.steps && step.steps.some(s => s.id == currentStepId)
        : currentStepId == step.id
    }

    const isCompleted = (step: Step, isActive: boolean): boolean => {
      if (isActive) return false
      return step.type == 'section'
        ? !!step.steps && step.steps.some(st => submissions.some(su => su.stepId == st.id))
        : submissions.some(su => su.stepId == step.id)
    }

    const wasSkipped = (step: Step, isActive: boolean, isCompleted: boolean, headedBySectionSteps: Array<Step>): boolean => {
      if (isActive || isCompleted) return false
      if (simulationIsEnded) {
        // if the simulation is ended (and the step is neither active nor completed)
        // then, it was skipped
        return true
      } else {
        return headedBySectionSteps.findIndex(s => s.id == step.id) < headedBySectionSteps.findIndex(s => s.id == currentStepId)
      }
    }

    const stepResponses = submissions.reduce(
      (stepResponses, submission) => {
        if (submission.response) stepResponses[submission.stepId] = submission.response
        return stepResponses
      },
      {}
    )
    const headedBySectionSteps = flatMapDepth(steps, step => {
      if (step.type == 'section') {
        return [
          step,
          step.steps
        ]
      } else {
        return step
      }
    }, 2)
    return {
      headedBySectionSteps: headedBySectionSteps.map(step => ({
        ...step,
        status: (
          isActive(step)
          ? 'active'
          : isCompleted(step, false)
            ? 'completed'
            : wasSkipped(step, false, false, headedBySectionSteps)
              ? 'skipped'
              : 'pending'
        ),
        response: stepResponses[step.id]
      }))
    }
  }

  render() {
    const { headedBySectionSteps } = this.state
    return <Card>
      <ul className='collection simulation'>
        {
          headedBySectionSteps.map((step, index) => <StepItem
            step={step}
            key={`step-item-${index}`}
          />)
        }
      </ul>
    </Card>
  }
})

type StepItemProps = {
  step: Step,
  t: Function
}

const StepItem = translate()(class extends Component<StepItemProps> {
  render() {
    const { step, t } = this.props
    const { type, title, response, status } = step
    const isSection = type == 'section'
    const isCompleted = status == 'completed'
    const itemClassNames = classNames(
      'collection-item',
      {
        done: isCompleted,
        skipped: status == 'skipped',
        active: status == 'active',
        pending: status == 'pending',
        section: isSection
      }
    )
    return <li className={itemClassNames}>
      <i className='material-icons left sharp'>{!isSection && isCompleted ? 'check_circle' : icon(type)}</i>
      <UntitledIfEmpty className='title' text={title} emptyText={isSection ? t('Untitled section') : t('Untitled question')} />
      <br />
      <span className='value'>{response}</span>
    </li>
  }
})

export default SimulationSteps
