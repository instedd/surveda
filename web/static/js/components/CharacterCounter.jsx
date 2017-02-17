import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as characterCounter from '../characterCounter'

class CharacterCounter extends Component {
  render() {
    const { text } = this.props
    const errorClass = characterCounter.limitExceeded(text) ? ' text-error' : ''
    return (
      <div>
        <span className={'character-counter' + errorClass}>
          {characterCounter.characterCount(text)}/{characterCounter.characterLimit(text)}
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
