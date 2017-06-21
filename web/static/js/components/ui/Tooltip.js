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
    const { position } = this.props
    const node = ReactDOM.findDOMNode(this.refs.node)
    const origin = $(node)
    const tooltip = origin.tooltip()[0]
    const tooltipId = tooltip.getAttribute('data-tooltip-id')
    $(`#${tooltipId}`).addClass(this.props.className)
    const tootlipElement = $('.material-tooltip')
    const margin = 5
    var tooltipHeight = tootlipElement.outerHeight()
    var tooltipWidth = tootlipElement.outerWidth()
    var originWidth = origin.outerWidth()
    var originHeight = origin.outerHeight()
    var targetTop, targetLeft, newCoordinates

    $(document).on('scroll', (context, args) => {
      if (position === 'top') {
        targetTop = origin.offset().top - tooltipHeight - margin
        targetLeft = origin.offset().left + originWidth / 2 - tooltipWidth / 2
        newCoordinates = this.repositionWithinScreen(targetLeft, targetTop, tooltipWidth, tooltipHeight)
      } else if (position === 'left') {
        targetTop = origin.offset().top + originHeight / 2 - tooltipHeight / 2
        targetLeft = origin.offset().left - tooltipWidth - margin
        newCoordinates = this.repositionWithinScreen(targetLeft, targetTop, tooltipWidth, tooltipHeight)
      } else if (position === 'right') {
        targetTop = origin.offset().top + originHeight / 2 - tooltipHeight / 2
        targetLeft = origin.offset().left + originWidth + margin
        newCoordinates = this.repositionWithinScreen(targetLeft, targetTop, tooltipWidth, tooltipHeight)
      } else {
        // Bottom Position
        targetTop = origin.offset().top + origin.outerHeight() + margin
        targetLeft = origin.offset().left + originWidth / 2 - tooltipWidth / 2
        newCoordinates = this.repositionWithinScreen(targetLeft, targetTop, tooltipWidth, tooltipHeight)
      }
      tootlipElement.css({
        top: newCoordinates.y,
        left: newCoordinates.x
      })
    })
  }

  repositionWithinScreen(x, y, width, height) {
    if (x < 0) {
      x = 4
    } else if (x + width > window.innerWidth) {
      x -= x + width - window.innerWidth
    }

    if (y < 0) {
      y = 4
    } else if (y + height > window.innerHeight + $(window).scrollTop) {
      y -= y + height - window.innerHeight
    }

    return {x: x, y: y}
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
