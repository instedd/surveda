import React, { Component, PropTypes } from 'react'
import { findDOMNode } from 'react-dom'
import { connect } from 'react-redux'
import { UntitledIfEmpty, Card } from '../ui'

import { DragSource, DropTarget } from 'react-dnd'

const stepSource = {
  beginDrag(props, monitor, component) {
    console.log('Dragging')
    console.log(props)

    const boundingBox = findDOMNode(component).getBoundingClientRect()

    console.log(boundingBox)

    const boxMiddleY = (boundingBox.bottom - boundingBox.top) / 2

    return {
      step: props.step,
      sourceMiddleY: boxMiddleY
    }
  }
}

const moveStep = (sourceStep, targetStep) => {
  console.log(`Move request from ${sourceStep.id} to ${targetStep.id}`)
}

const collectSource = (connect, monitor) => {
  return {
    connectDragSource: connect.dragSource(),
    isDragging: monitor.isDragging()
  }
}

const collectTarget = (connect, monitor) => {
  return {
    connectDropTarget: connect.dropTarget()
  }
}

const stepTarget = {
  hover(props, monitor, component) {
    const { step, sourceMiddleY } = props

    const dragStep = monitor.getItem().step
    const hoverStep = step

    // Don't replace items with themselves
    if (dragStep.id === hoverStep.id) {
      return
    }

    // Determine rectangle on screen
    const hoverBoundingRect = findDOMNode(component).getBoundingClientRect()

    // Get vertical middle
    const hoverMiddleY = (hoverBoundingRect.bottom - hoverBoundingRect.top) / 2

    // Determine mouse position
    const clientOffset = monitor.getClientOffset()

    // Get pixels to the top
    const hoverClientY = clientOffset.y - hoverBoundingRect.top

    // Only perform the move when the mouse has crossed half of the items height
    // When dragging downwards, only move when the cursor is below 50%
    // When dragging upwards, only move when the cursor is above 50%

    // Dragging downwards
    if (sourceMiddleY < hoverMiddleY && hoverClientY < hoverMiddleY) {
      return
    }

    // Dragging upwards
    if (sourceMiddleY > hoverMiddleY && hoverClientY > hoverMiddleY) {
      return
    }

    // Time to actually perform the action
    moveStep(dragStep, hoverStep)

    // Note: we're mutating the monitor item here!
    // Generally it's better to avoid mutations,
    // but it's good here for the sake of performance
    // to avoid expensive index searches.
    // monitor.getItem().index = hoverIndex
  }
}

class QuestionnaireClosedStep extends Component {
  render() {
    const { step, onClick, isDragging, connectDragSource, connectDropTarget } = this.props

    return connectDropTarget(connectDragSource(
      <div style={{opacity: isDragging ? 0.0 : 1, cursor: 'move'}}>
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

QuestionnaireClosedStep.propTypes = {
  step: PropTypes.object.isRequired,
  onClick: PropTypes.func.isRequired,
  isDragging: PropTypes.bool.isRequired,
  connectDragSource: PropTypes.func.isRequired,
  connectDropTarget: PropTypes.func.isRequired
}

const source = DragSource('STEPS', stepSource, collectSource)(QuestionnaireClosedStep)
const target = DropTarget('STEPS', stepTarget, collectTarget)(source)

export default connect()(target)
