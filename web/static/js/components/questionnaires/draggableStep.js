export const stepSource = {
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
