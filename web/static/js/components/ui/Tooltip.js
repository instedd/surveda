import React, { Component } from 'react'
import ReactDOM from 'react-dom'

export class Tooltip extends Component {
  static defaultProps = {
    position: 'top',
    delay: 20
  }

  static propTypes = {
    children: React.PropTypes.node.isRequired,
    position: React.PropTypes.oneOf(['top', 'right', 'bottom', 'left']),
    delay: React.PropTypes.number,
    text: React.PropTypes.string.isRequired,
    className: React.PropTypes.string
  }

  componentDidMount() {
    this.updateTooltip()
  }

  componentDidUpdate() {
    this.updateTooltip()
  }

  updateTooltip() {
    const node = ReactDOM.findDOMNode(this.refs.node)
    const tooltip = $(node).tooltip()[0]
    const tooltipId = tooltip.getAttribute('data-tooltip-id')
    $(`#${tooltipId}`).addClass(this.props.className)
  }

  componentWillUnmount() {
    const node = ReactDOM.findDOMNode(this.refs.node)
    $(node).tooltip('remove')
  }

  render() {
    const { children, position, delay, text } = this.props
    const child = React.Children.only(children)

    return React.cloneElement(child, {
      className: child.props.className + ' tooltipped',
      'data-position': position,
      'data-delay': delay,
      'data-tooltip': text,
      'ref': 'node'
    })
  }
}
