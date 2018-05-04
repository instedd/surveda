// @flow
import React, { Component, PropTypes } from 'react'

type Props = {
  text: string
};

class Prompt extends Component<Props> {
  render() {
    const { text } = this.props
    return <div className={'prompt'}><h1 dangerouslySetInnerHTML={{__html: text}} /></div>
  }
}

export default Prompt
