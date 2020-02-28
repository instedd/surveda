// @flow
import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

type Props = {
  introMessage: string,
  onClick: Function
};

class IntroStep extends Component<Props> {
  render() {
    const { introMessage, onClick } = this.props

    return (
      <div>
        <Prompt key={introMessage} text={introMessage} />
        <button type="button" className='btn large block' style={{borderColor: this.context.primaryColor, color: this.context.primaryColor}} onClick={onClick}>
          <svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24">
            <path d="M0 0h24v24H0z" fill="none"/>
            <path d="M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8z"/>
          </svg>
        </button>
      </div>
    )
  }
}

IntroStep.contextTypes = {
  primaryColor: PropTypes.string
}

export default IntroStep
