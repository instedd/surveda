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
          <svg height='24' viewBox='0 0 24 24' width='24' xmlns='http://www.w3.org/2000/svg'>
            <path d='M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z' fill={this.context.primaryColor} />
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
