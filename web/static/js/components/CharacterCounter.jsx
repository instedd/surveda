import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as characterCounter from '../characterCounter'

class CharacterCounter extends Component {
  render() {
    let { fixedLength, text } = this.props
    if (!fixedLength) fixedLength = 0

    text += 'a'.repeat(fixedLength)

    const counter = characterCounter.count(text)
    return (
      <div>
        <span className={'character-counter'}>
          {counter.count - fixedLength}/{counter.limit - fixedLength}
        </span>
      </div>
    )
  }
}

CharacterCounter.propTypes = {
  text: PropTypes.string.isRequired,
  fixedLength: PropTypes.number
}

const mapStateToProps = (state, ownProps) => ({
  text: ownProps.text,
  fixedLength: ownProps.fixedLength
})

export default connect(mapStateToProps)(CharacterCounter)
