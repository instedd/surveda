import React, { Component } from 'react'

export class Tabs extends Component {
  componentDidMount() {
    $(this.refs.node).tabs()
  }

  render() {
    const { children } = this.props
    return (
      <ul className="tabs" key="foo" ref="node">
        {children}
      </ul>
    )
  }
}
