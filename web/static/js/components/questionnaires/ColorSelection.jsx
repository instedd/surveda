import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

class ColorSelection extends Component {

  render() {
    return (
      <div>
        Color selection
      </div>
    )
  }
}

ColorSelection.propTypes = {
}

export default connect()(ColorSelection)
