import React, { Component, PropTypes } from 'react'
import * as uiActions from '../../actions/ui'
import { connect } from 'react-redux'

class QuestionnaireImport extends Component {
  constructor(props) {
    super(props)
    this.onCancel = this.onCancel.bind(this)
  }

  onCancel() {
    const { uploadId } = this.props
    if (uploadId) {
      uiActions.uploadCancelled(uploadId)
    }
  }

  render() {
    const sqSize = 174
    const strokeWidth = 6
    const radius = (sqSize - strokeWidth) / 2
    const viewBox = `0 0 ${sqSize} ${sqSize}`
    const dashArray = radius * Math.PI * 2
    const dashOffset = dashArray - dashArray * this.props.percentage / 100

    return (
      <div className='center-align'>
        <svg
          width={sqSize}
          height={sqSize}
          viewBox={viewBox}>
          <path fill='#999999' transform='translate(12,12)' d='M75,0c41.4,0,75,33.6,75,75s-33.6,75-75,75S0,116.4,0,75S33.6,0,75,0L75,0z M48.4,106.9h52.4v-7.6H48.4V106.9z M85.8,91.8V69.3h14.9L74.6,43.1L48.4,69.3h14.9v22.5L85.8,91.8L85.8,91.8z' />
          <circle
            className='circle-progress'
            cx={sqSize / 2}
            cy={sqSize / 2}
            r={radius}
            strokeWidth={`${strokeWidth}px`}
            // Start progress marker at 12 O'Clock
            transform={`rotate(-90 ${sqSize / 2} ${sqSize / 2})`}
            style={{
              strokeDasharray: dashArray,
              strokeDashoffset: dashOffset
            }} />
        </svg>
        <h5 className='grey-text lighten-1'>
          Uploading questionnaire
        </h5>
        <br />
        <a href='#!' onClick={this.onCancel} className='btn-large red'>
          Cancel
        </a>
      </div>
    )
  }
}

QuestionnaireImport.propTypes = {
  percentage: PropTypes.number,
  uploadId: PropTypes.number
}

const mapStateToProps = (state, ownProps) => ({
  uploadId: state.ui.data.questionnaireEditor.upload.uploadId
})

export default connect(mapStateToProps)(QuestionnaireImport)
