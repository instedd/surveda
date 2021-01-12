import React, { Component } from 'react'

const margin = {left: 18, top: 18, right: 18, bottom: 18}

type Props = {
  weight: number,
  exhausted: number,
  available: number,
  needed: number,
  additionalCompletes: number,
  additionalRespondents: number
}

type State = {
  width: number,
  height: number
}

export default class QueueSize extends Component<Props, State> {
  constructor(props) {
    super(props)
    this.recalculate = this.recalculate.bind(this)
    this.state = {
      width: 0,
      height: 0
    }
  }

  componentDidMount() {
    window.addEventListener('resize', this.recalculate)
    this.recalculate()
    this.alignContent()
  }

  componentDidUpdate() {
    this.alignContent()
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.recalculate)
  }

  recalculate() {
    const { container } = this.refs
    const containerRect = container.getBoundingClientRect()

    const width = Math.round(containerRect.width) - margin.left - margin.right
    const height = Math.round(width / 2)

    this.setState({width, height})
  }

  alignContent() {
    const height = this.state.height - margin.top - margin.bottom
    const boundingBox = this.refs.content.getBBox()
    const offset = (height - boundingBox.height + this.props.weight) / 2 - boundingBox.y
    this.refs.content.setAttribute('transform', `translate(0,${offset})`)
  }

  connector(x1, y1, x2, y2, turn, cornerHeight) {
    const direction = x1 < x2 ? 1 : -1
    const cornerWidth = Math.min(Math.abs(x1 - x2) / 2, cornerHeight)

    return `M${x1} ${y1}
            v${turn - cornerHeight}
            q0 ${cornerHeight},${cornerWidth * direction} ${cornerHeight}
            h${x2 - x1 - cornerWidth * 2 * direction}
            q${cornerWidth * direction} 0,${cornerWidth * direction} ${cornerHeight}
            V${y2}`
  }

  render() {
    const toKilo = num => num > 999 ? (num / 1000).toFixed(1) + 'K' : num
    const {exhausted, available, needed, additionalCompletes, additionalRespondents, weight} = this.props
    const width = Math.max(this.state.width - margin.left - margin.right, 0)
    const height = Math.max(this.state.height - margin.top - margin.bottom, 0)
    const scale = Math.min(1, width / needed, width / (exhausted + available) / 2)
    const offset = 12
    const corner = 6
    const left = {
      x1: (exhausted - available) * scale / 2,
      y1: weight,
      x2: -needed * scale / 2,
      y2: height - weight}
    const right = {
      x1: (exhausted + available) * scale / 2,
      y1: weight,
      x2: needed * scale / 2,
      y2: height - weight
    }

    return (
      <div ref='container'>
        <svg className='queueSize' width={width + margin.left + margin.right} height={height + margin.top + margin.bottom}>
          <g transform={`translate(${margin.top}, ${margin.left})`}>
            <g transform={`translate(${width / 2},0)`}>
              <g transform={`translate(${-(available + exhausted) * scale / 2},0)`}>
                <rect width={exhausted * scale} height={weight} className='queueProgress' />
                <rect width={available * scale} height={weight} x={exhausted * scale} className='background' />
                <text x={-offset} y={weight / 2} className='queueProgress label end'>{toKilo(exhausted)} exhausted</text>
                <text x={(available + exhausted) * scale + offset} y={weight / 2} className='background label start'>{toKilo(available)} available</text>
              </g>
              <path style={{display: needed ? 'auto' : 'none'}} className='dottedLine' d={this.connector(left.x1, left.y1, left.x2, left.y2, weight - (left.x1 > left.x2 && right.x1 > right.x2 ? corner : 0), corner)} />
              <path style={{display: needed ? 'auto' : 'none'}} className='dottedLine' d={this.connector(right.x1, right.y1, right.x2, right.y2, weight, corner)} />
              <g ref='content'>
                <text className='needed'>{`${toKilo(needed)} respondents needed`}</text>
                <text className='multiplier' y={18}>{`to have ${additionalCompletes ? toKilo(additionalCompletes) : 0} additional completes`}</text>
                {additionalRespondents ? <text className='missing' y={54} ><tspan className='icon'>warning</tspan> {`Add ${toKilo(additionalRespondents)} additional respondents`}</text> : null}
              </g>
            </g>
            <g transform={`translate(0,${height - weight})`}>
              <rect width={needed * scale} height={weight} x={(width - needed * scale) / 2} />
              {additionalRespondents ? <rect className='missing' width={additionalRespondents * scale} height={weight} x={(width - additionalRespondents * scale) - (width - needed * scale) / 2} /> : null}
            </g>
          </g>
        </svg>
      </div>
    )
  }
}
