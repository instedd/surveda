// @flow
import React, { Component } from 'react'
import { UntitledIfEmpty, Card } from '../ui'
import DraggableStep from './DraggableStep'

type Props = {
  step: Step,
  onClick: Function
}

class QuestionnaireClosedStep extends Component {
  props: Props

  render() {
    const { step, onClick } = this.props

    return (
      <DraggableStep step={step}>
        <Card>
          <div className='card-content closed-step'>
            <div>
              <a href='#!' className='truncate' onClick={event => {
                event.preventDefault()
                onClick(step.id)
              }}>
                {step.type == 'multiple-choice' ? <i className='material-icons left'>list</i> : step.type == 'numeric' ? <i className='material-icons sharp left'>dialpad</i> : step.type == 'explanation' ? <i className='material-icons sharp left'>chat_bubble_outline</i> : <i className='material-icons left'>language</i>}
                <UntitledIfEmpty text={step.title} emptyText='Untitled question' />
                <i className='material-icons right grey-text'>expand_more</i>
              </a>
            </div>
          </div>
        </Card>
      </DraggableStep>
    )
  }
}

export default QuestionnaireClosedStep
