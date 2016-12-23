import React, { Component, PropTypes } from 'react'
import StepEditor from './StepEditor'

class StepEditorSwitcher extends Component {

  render() {
    const { step, errorPath, onCollapse, onDelete, stepsAfter } = this.props

    return (
      <StepEditor
        step={step}
        errorPath={errorPath}
        onCollapse={() => onCollapse()}
        onDelete={() => onDelete()}
        stepsAfter={stepsAfter} />
    )
  }
}

StepEditorSwitcher.propTypes = {
  step: PropTypes.object.isRequired,
  errorPath: PropTypes.string.isRequired,
  onCollapse: PropTypes.func.isRequired,
  onDelete: PropTypes.func.isRequired,
  stepsAfter: PropTypes.array.isRequired
}

export default StepEditorSwitcher
