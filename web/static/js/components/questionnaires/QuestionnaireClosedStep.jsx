// @flow
import React, { Component } from 'react'
import { connect } from 'react-redux'
import { UntitledIfEmpty, Card } from '../ui'
import { DragSource, DropTarget } from 'react-dnd'
import { stepSource, collectSource, stepTarget, collectTarget } from './draggableStep'

type Props = {
  step: Step,
  onClick: Function,
  onMoveUnderStep: Function,
  isDragging: boolean,
  isOver: boolean,
  connectDragSource: Function,
  connectDropTarget: Function,
  draggable: boolean
}

class QuestionnaireClosedStep extends Component {
  props: Props

  render() {
    const { step, onClick, isDragging, connectDragSource, connectDropTarget, isOver, draggable } = this.props

    const renderedStep =
      <Card>
        <div className='card-content closed-step'>
          <div>
            <a href='#!' className='truncate' onClick={event => {
              event.preventDefault()
              onClick(step.id)
            }}>
              {step.type == 'multiple-choice' ? <i className='material-icons left'>list</i> : step.type == 'numeric' ? <i className='material-icons sharp left'>dialpad</i> : <i className='material-icons left'>language</i>}
              <UntitledIfEmpty text={step.title} emptyText='Untitled question' />
              <i className='material-icons right grey-text'>expand_more</i>
            </a>
          </div>
        </div>
      </Card>

    if (draggable) {
      const draggableStyle = {
        opacity: isDragging ? 0.0 : 1,
        cursor: 'move',
        borderBottom: isOver ? 'green medium solid' : 'inherit'
      }

      return connectDropTarget(connectDragSource(
        <div style={draggableStyle}>
          {renderedStep}
        </div>
      ))
    } else {
      return renderedStep
    }
  }
}

const source = DragSource('STEPS', stepSource, collectSource)(QuestionnaireClosedStep)
const target = DropTarget('STEPS', stepTarget, collectTarget)(source)

export default connect()(target)
