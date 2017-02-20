import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as characterCounter from '../characterCounter'

class CharacterCounter extends Component {
  render() {
    const { text } = this.props
    const errorClass = characterCounter.limitExceeded(text) ? ' text-error' : ''
    const counter = characterCounter.count(text)
    return (
      <div>
        <span className={'character-counter' + errorClass}>
          {counter.count}/{counter.limit}
        </span>
      </div>
    )
  }
}

CharacterCounter.propTypes = {
  text: PropTypes.string.isRequired
}

const mapStateToProps = (state, ownProps) => ({
  text: ownProps.text
})

export default connect(mapStateToProps)(CharacterCounter)
