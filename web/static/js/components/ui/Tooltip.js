import React, { Component } from 'react'
import ReactDOM from 'react-dom'
import throttle from 'lodash/throttle'

export class Tooltip extends Component {
  recalculate: Function
  static propTypes = {
    children: React.PropTypes.node.isRequired,
    position: React.PropTypes.oneOf(['top', 'right', 'bottom', 'left']),
    delay: React.PropTypes.number,
    text: React.PropTypes.string.isRequired,
    className: React.PropTypes.string
  }

  static defaultProps = {
    position: 'top',
    delay: 20
  }

  constructor(props: Props) {
    super(props)
    this.hideTooltip = throttle(this.hideTooltip.bind(this), 225)
    this.recalculate = this.recalculate.bind(this)
  }

  componentDidMount() {
    this.updateTooltip()
    window.addEventListener('scroll', this.hideTooltip)
    window.addEventListener('scroll', this.recalculate)
  }

  componentWillUnmount() {
    window.removeEventListener('scroll', this.hideTooltip)
    window.removeEventListener('scroll', this.recalculate)
    const node = ReactDOM.findDOMNode(this.refs.node)
    $(node).tooltip('remove')
  }

  componentDidUpdate(prevProps) {
    const { position, delay, text } = this.props
    if (position !== prevProps.position || delay !== prevProps.delay || text !== prevProps.text) {
      this.updateTooltip()
    }
  }

  updateTooltip() {
    const node = ReactDOM.findDOMNode(this.refs.node)
    const tooltip = $(node).tooltip()[0]
    const tooltipId = tooltip.getAttribute('data-tooltip-id')
    $(`#${tooltipId}`).addClass(this.props.className)
  }

  hideTooltip() {
    const tootlipElement = $('.material-tooltip')
    const backdrop = $('.backdrop')
    tootlipElement.velocity({
      opacity: 0, translateY: 0, translateX: 0}, {duration: 225, queue: false})
    backdrop.velocity({opacity: 0, scaleX: 1, scaleY: 1}, {
      duration: 225,
      queue: false,
      complete: function() {
        backdrop.css({ visibility: 'hidden' })
        tootlipElement.css({ visibility: 'hidden' })
      }
    })
  }

  recalculate() {
    const tootlipElement = $('.material-tooltip')
    const { position } = this.props
    const origin = $(ReactDOM.findDOMNode(this.refs.node))

    const margin = 5
    var tooltipHeight = tootlipElement.outerHeight()
    var tooltipWidth = tootlipElement.outerWidth()
    var originWidth = origin.outerWidth()
    var originHeight = origin.outerHeight()
    var targetTop, targetLeft, newCoordinates

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
