import React, { Component } from 'react'
import rd3 from 'react-d3-library';
const RD3Component = rd3.Component;
import {timeWeek, timeMonth} from 'd3-time'

class RespondentsChart extends Component {
  constructor(props){
    super(props)
    this.state = { d3: '' }
  }

  //Init
  componentWillMount(){
    const { completedByDate, margin, width, height } = this.props

    const node = document.createElement('div')
    const svg = d3.select(node).append("svg")

    const x = d3.time.scale()
    const y = d3.scale.linear().domain([0,1])
    const yaxis = d3.svg.axis()
                        .scale(y)
                        .ticks(10)
                        .tickSize(width)
                        .orient("right")
    const xaxis = d3.svg.axis()
                        .scale(x)
    const line = d3.svg.line()
                        .x(function(d) { return x(d.date) })
                        .y(function(d) { return y(d.count) })

    this.init(svg, margin, width, height)
    this.setSize(x, y, margin, width, height)
    this.setState({ d3: node, svg: svg, x: x, y: y, yaxis: yaxis, xaxis: xaxis, line: line, margin: margin, width: width, height: height})
  }

  data(completedByDate, x, y){
    const formatDate = function(date){return new Date(Date.parse(date))}
    const data =  completedByDate.map((d) => { return { date: formatDate(d.date), count: Number(d.count) } } )
    x.domain(d3.extent(data, function(d) { return d.date; }));
    return data
  }

  setSize(x, y, margin, width, height){
    const w = width
    const h = height
    x.range([0, w])
    y.range([h, 0])
  }

  init(svg, margin, width, height){
    const container = svg.append("g")
    const YAxis = container.append("g")
                          .attr("class", "y axis")
                          .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
    const XAxis = container.append("g")
                          .attr("class", "x axis")
                          .attr("transform", "translate(" + margin.left + "," + (margin.top+height) + ")")
    const path = container.append("path")
                          .attr("class", "line")
                          .attr("transform", "translate(" + margin.left + "," + (margin.top) + ")")
    this.setState({YAxis: YAxis, XAxis: XAxis, path: path})
  }

  render(){
    const { completedByDate } = this.props
    const { d3, svg, width, height, margin, YAxis, XAxis, path, line, yaxis, xaxis, x, y } = this.state

    if(!svg){
      return <div>Loading...</div>
    }

    const data = this.data(completedByDate, x, y)

    svg.attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)

    YAxis.call(yaxis)
        .selectAll("text")
          .attr("x", -25)

    XAxis.call(xaxis)

    path.datum(data)
        .attr("class", "line")
        .attr("d", line)

    return(
      <div>
        <RD3Component data={d3}/>
      </div>
    )
  }
}

export default RespondentsChart
