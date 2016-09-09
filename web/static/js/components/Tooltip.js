import React, { Component } from 'react'
import ReactDOM from 'react-dom'

export class Tooltip extends Component {
  componentDidMount() {
    const node = ReactDOM.findDOMNode(this.refs.node)
    $(node).tooltip()
  }

  componentWillUnmount() {
    const node = ReactDOM.findDOMNode(this.refs.node)
    $(node).tooltip('remove')
  }

  render() {
    const { children, position, delay, text } = this.props
    const child = React.Children.only(children)

    return React.cloneElement(child, {
      className: child.props.className + " tooltipped",
      "data-position": position,
      "data-delay": delay,
      "data-tooltip": text,
      "ref": "node"
    })
  }
}

Tooltip.propTypes = {
  children: React.PropTypes.element.isRequired,
  position: React.PropTypes.oneOf(['top', 'right', 'bottom', 'left']),
  delay: React.PropTypes.number,
  text: React.PropTypes.string.isRequired
}

Tooltip.defaultProps = {
  position: 'top',
  delay: 20
}
