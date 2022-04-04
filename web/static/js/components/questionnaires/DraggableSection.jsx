// @flow weak
import React, { Component } from "react"
import { bindActionCreators } from "redux"
import { connect } from "react-redux"
import { DragSource, DropTarget } from "react-dnd"
import * as questionnaireActions from "../../actions/questionnaire"

type Props = {
  sectionId: string,
  isDragging: boolean,
  isOver: boolean,
  connectDragSource: Function,
  connectDropTarget: Function,
  children: any,
  questionnaireActions: any,
  readOnly: boolean,
  dropOnly: boolean,
}

class DraggableSection extends Component<Props> {
  static defaultProps = { dropOnly: false }
  draggableSection() {
    const { isDragging, isOver, connectDragSource, children, readOnly, dropOnly } = this.props

    const draggable = !readOnly

    let draggableStyle: any = {
      opacity: isDragging ? 0.0 : 1,
      cursor: draggable ? "move" : "",
    }

    if (isOver) {
      draggableStyle["borderBottom"] = "green medium solid"
    }

    const renderedDraggable = <div style={draggableStyle}>{children}</div>

    if (draggable && !dropOnly) {
      return connectDragSource(renderedDraggable)
    } else {
      return renderedDraggable
    }
  }

  render() {
    const { connectDropTarget } = this.props
    return connectDropTarget(this.draggableSection())
  }
}

export const sectionSource = {
  beginDrag(props, monitor, component) {
    return {
      id: props.sectionId,
    }
  },

  endDrag(props, monitor, component) {
    const { sectionId, questionnaireActions } = props

    if (monitor.didDrop()) {
      const { sectionId: targetSectionId } = monitor.getDropResult()
      targetSectionId
        ? questionnaireActions.moveSection(sectionId, targetSectionId)
        : questionnaireActions.moveSection(sectionId)
    }
  },
}

export const collectSource = (connect, monitor) => {
  return {
    connectDragSource: connect.dragSource(),
    isDragging: monitor.isDragging(),
  }
}

export const collectTarget = (connect, monitor) => {
  return {
    connectDropTarget: connect.dropTarget(),
    isOver: monitor.isOver(),
  }
}

export const sectionTarget = {
  drop(props, monitor) {
    return { sectionId: props.sectionId }
  },
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
})

const source = DragSource("section", sectionSource, collectSource)(DraggableSection)
const target = DropTarget("section", sectionTarget, collectTarget)(source)

export default connect(null, mapDispatchToProps)(target)
