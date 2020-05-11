// @flow
import React, { Component } from 'react'
import { icon } from '../../step'
import { translate } from 'react-i18next'
import { Card, UntitledIfEmpty } from '../ui'
import classNames from 'classnames/bind'

type Step = {
  type: string,
  title: string,
  id: string
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
    return <Card>
      <ul className='collection simulation'>
        {
          steps.map((step, index) => <StepItem
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
    return <li className={classNames({ 'collection-item': true, done: completed, active })}>
      <i className='material-icons left sharp'>{completed ? 'check_circle' : icon(stepType)}</i>
      <UntitledIfEmpty className='title' text={title} emptyText={stepType == 'section' ? t('Untitled section') : t('Untitled question')} />
      <br />
      <span className='value'>{response}</span>
    </li>
  }
})

export default SimulationSteps
