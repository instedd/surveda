// @flow
import React, { Component } from 'react'
import { connect } from 'react-redux'
import { UntitledIfEmpty, Card } from '../ui'

import { DragSource, DropTarget } from 'react-dnd'

const stepSource = {
  beginDrag(props, monitor, component) {
    return {
      id: props.step.id
    }
  },

  endDrag(props, monitor, component) {
    const { step, onMoveUnderStep } = props

    if (monitor.didDrop() && monitor.getDropResult().id != step.id) {
      onMoveUnderStep(step.id, monitor.getDropResult().id)
    }
  }
}

const collectSource = (connect, monitor) => {
  return {
    connectDragSource: connect.dragSource(),
    isDragging: monitor.isDragging()
  }
}

const collectTarget = (connect, monitor) => {
  return {
    connectDropTarget: connect.dropTarget(),
    isOver: monitor.isOver()
  }
}

const stepTarget = {
  drop(props, monitor) {
    return { id: props.step.id }
  }
}

type Props = {
  step: Step,
  onClick: Function,
  onMoveUnderStep: Function,
  isDragging: boolean,
  isOver: boolean,
  connectDragSource: Function,
  connectDropTarget: Function
}

class QuestionnaireClosedStep extends Component {
  props: Props

  render() {
    const { step, onClick, isDragging, connectDragSource, connectDropTarget, isOver } = this.props

    return connectDropTarget(connectDragSource(
      <div style={{
        opacity: isDragging ? 0.0 : 1,
        cursor: 'move',
        borderBottom: isOver ? 'green medium solid' : 'inherit'
      }}>
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
      </div>
    ))
  }
}

const source = DragSource('STEPS', stepSource, collectSource)(QuestionnaireClosedStep)
const target = DropTarget('STEPS', stepTarget, collectTarget)(source)

export default connect()(target)
