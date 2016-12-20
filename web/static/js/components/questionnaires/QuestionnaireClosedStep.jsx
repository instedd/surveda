import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { UntitledIfEmpty } from '../ui'

import { DragSource, DropTarget } from 'react-dnd'

const stepSource = {
  beginDrag(props) {
    console.log('Dragging')
    console.log(props)
    return {
      stepId: props.step.id
    }
  }
}

const stepTarget = {
  drop(props, monitor) {
    console.log(`Move request from ${monitor.getItem().stepId} to ${props.step.id}`)
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

class QuestionnaireClosedStep extends Component {
  render() {
    const { step, onClick, isDragging, connectDragSource, connectDropTarget, isOver } = this.props

    return connectDropTarget(connectDragSource(
      <div style={{
        opacity: isDragging ? 0.5 : 1,
        cursor: 'move',
        backgroundColor: isOver ? 'yellow' : 'inherit'
      }}>
        <a href='#!' className='truncate' onClick={event => {
          event.preventDefault()
          onClick(step.id)
        }}>
          {step.type == 'multiple-choice' ? <i className='material-icons left'>list</i> : step.type == 'numeric' ? <i className='material-icons sharp left'>dialpad</i> : <i className='material-icons left'>language</i>}
          <UntitledIfEmpty text={step.title} emptyText='Untitled question' />
          <i className='material-icons right grey-text'>expand_more</i>
        </a>
      </div>
    ))
  }
}

QuestionnaireClosedStep.propTypes = {
  step: PropTypes.object.isRequired,
  onClick: PropTypes.func.isRequired,
  isDragging: PropTypes.bool.isRequired,
  isOver: PropTypes.bool.isRequired,
  connectDragSource: PropTypes.func.isRequired,
  connectDropTarget: PropTypes.func.isRequired
}

const source = DragSource('STEPS', stepSource, collectSource)(QuestionnaireClosedStep)
const target = DropTarget('STEPS', stepTarget, collectTarget)(source)

export default connect()(target)
