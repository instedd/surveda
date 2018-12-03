import React, { Component, PropTypes } from 'react'

class QuestionnaireImport extends Component {
  render() {
    const sqSize = this.props.sqSize
    const radius = (this.props.sqSize - this.props.strokeWidth) / 2
    const viewBox = `0 0 ${sqSize} ${sqSize}`
    const dashArray = radius * Math.PI * 2
    const dashOffset = dashArray - dashArray * this.props.percentage / 100

    return (
      <svg
        id='questionnaireImport'
        width={this.props.sqSize}
        height={this.props.sqSize}
        viewBox={viewBox}>
        <path fill='#999999' transform='translate(12,12)' d='M75,0c41.4,0,75,33.6,75,75s-33.6,75-75,75S0,116.4,0,75S33.6,0,75,0L75,0z M48.4,106.9h52.4v-7.6H48.4V106.9z M85.8,91.8V69.3h14.9L74.6,43.1L48.4,69.3h14.9v22.5L85.8,91.8L85.8,91.8z' />
        <circle
          className='circle-progress'
          cx={this.props.sqSize / 2}
          cy={this.props.sqSize / 2}
          r={radius}
          strokeWidth={`${this.props.strokeWidth}px`}
          // Start progress marker at 12 O'Clock
          transform={`rotate(-90 ${this.props.sqSize / 2} ${this.props.sqSize / 2})`}
          style={{
            strokeDasharray: dashArray,
            strokeDashoffset: dashOffset
          }} />
      </svg>
    )
  }
}

QuestionnaireImport.propTypes = {
  percentage: PropTypes.number.isRequired,
  sqSize: PropTypes.number.isRequired,
  strokeWidth: PropTypes.strokeWidth.isRequired
}

export default QuestionnaireImport
