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
  questionnaireActions: any,
  quotaCompletedSteps: boolean,
  readOnly: boolean
};

class DraggableStep extends Component {
  props: Props

  draggableStep() {
    const { step, isDragging, isOver, connectDragSource, children, readOnly } = this.props

    const draggable = !readOnly && (step == null || step.type != 'language-selection')

    let draggableStyle: any = {
      opacity: isDragging ? 0.0 : 1,
      cursor: draggable ? 'move' : ''
    }

    if (isOver) {
      draggableStyle['borderBottom'] = 'green medium solid'
    }

    const renderedDraggable =
      <div style={draggableStyle}>
        {children}
      </div>

    if (draggable) {
      return connectDragSource(renderedDraggable)
    } else {
      return renderedDraggable
    }
  }

  render() {
    const { connectDropTarget } = this.props
    return connectDropTarget(this.draggableStep())
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

    if (monitor.didDrop()) {
      if (monitor.getDropResult().step == null) {
        questionnaireActions.moveStepToTop(step.id)
      } else if (monitor.getDropResult().step.id !== step.id) {
        questionnaireActions.moveStep(step.id, monitor.getDropResult().step.id)
      }
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
    return { step: props.step }
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

const typeFromProps = (props) => {
  if (props.quotaCompletedSteps) {
    return 'QUOTA_COMPLETED_STEPS'
  } else {
    return 'STEPS'
  }
}

const source = DragSource(typeFromProps, stepSource, collectSource)(DraggableStep)
const target = DropTarget(typeFromProps, stepTarget, collectTarget)(source)

export default connect(null, mapDispatchToProps)(target)
