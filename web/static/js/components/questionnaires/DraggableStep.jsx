// @flow weak
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { DragSource, DropTarget } from 'react-dnd'
import * as questionnaireActions from '../../actions/questionnaire'

type Props = {
  step: Step,
  isDragging: boolean,
  isOver: boolean,
  connectDragSource: Function,
  connectDropTarget: Function,
  children: any,
  questionnaireActions: any
}

class DraggableStep extends Component {
  props: Props

  render() {
    const { step, isDragging, isOver, connectDropTarget, connectDragSource, children } = this.props

    const draggable = step.type != 'language-selection'

    if (draggable) {
      const draggableStyle = {
        opacity: isDragging ? 0.0 : 1,
        cursor: 'move',
        borderBottom: isOver ? 'green medium solid' : 'inherit'
      }

      return connectDropTarget(connectDragSource(
        <div style={draggableStyle}>
          {children}
        </div>
      ))
    } else {
      return children
    }
  }
}

export const stepSource = {
  beginDrag(props, monitor, component) {
    return {
      id: props.step.id
    }
  },

  endDrag(props, monitor, component) {
    const { step, questionnaireActions } = props

    if (monitor.didDrop() && monitor.getDropResult().id != step.id) {
      questionnaireActions.moveStep(step.id, monitor.getDropResult().id)
    }
  }
}

export const collectSource = (connect, monitor) => {
  return {
    connectDragSource: connect.dragSource(),
    isDragging: monitor.isDragging()
  }
}

export const collectTarget = (connect, monitor) => {
  return {
    connectDropTarget: connect.dropTarget(),
    isOver: monitor.isOver()
  }
}

export const stepTarget = {
  drop(props, monitor) {
    return { id: props.step.id }
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

const source = DragSource('STEPS', stepSource, collectSource)(DraggableStep)
const target = DropTarget('STEPS', stepTarget, collectTarget)(source)

export default connect(null, mapDispatchToProps)(target)
