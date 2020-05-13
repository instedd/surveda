// @flow
import React, { Component } from 'react'
import { icon } from '../../step'
import { translate } from 'react-i18next'
import { Card, UntitledIfEmpty } from '../ui'
import classNames from 'classnames/bind'
import { flatMapDepth } from 'lodash'

type Step = {
  type: string,
  title: string,
  id: string,
  steps: ?Array<Step>
}

type Submission = {
  id: string, // stepId
  response: ?string
}

type Props = {
  submissions: Array<Submission>,
  steps: Array<Step>,
  currentStepId: string,
  t: Function
}

const SimulationSteps = translate()(class extends Component<Props> {
  render() {
    const { steps, currentStepId, submissions } = this.props
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

    return <Card>
      <ul className='collection simulation'>
        {
          headedBySectionSteps.map((step, index) => <StepItem
            stepType={step.type}
            title={step.title}
            completed={submissions.some(s => s.id == step.id)}
            active={step.id == currentStepId}
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
  completed: ?boolean,
  active: ?boolean,
  t: Function
}

const StepItem = translate()(class extends Component<StepItemProps> {
  render() {
    const { stepType, title, response, completed, active, t } = this.props
    const isSection = stepType == 'section'
    return <li className={classNames('collection-item', { done: completed, active, section: isSection })}>
      <i className='material-icons left sharp'>{completed ? 'check_circle' : icon(stepType)}</i>
      <UntitledIfEmpty className='title' text={title} emptyText={isSection ? t('Untitled section') : t('Untitled question')} />
      <br />
      <span className='value'>{response}</span>
    </li>
  }
})

export default SimulationSteps
