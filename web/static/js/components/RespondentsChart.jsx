import React, { Component } from 'react'
import rd3 from 'react-d3-library';
const RD3Component = rd3.Component;
import {timeWeek, timeMonth} from 'd3-time'

class RespondentsChart extends Component {
  constructor(props){
    super(props)
    this.state = { d3: '' }
  }

  componentWillMount(){
    const { completedByDate, width, height } = this.props

    const node = document.createElement('div')

    const svg = d3.select(node).append("svg")
    .attr("width", width)
    .attr("height", height)
    .append("g")

    this.setState({d3: node})
    this.create([], node, width, height)
  }

  create(completedByDate, node, width, height){
    const svg = d3.select(node).select("svg")

    const formatDate = d3.time.format("%d-%b-%y")

    const x = d3.time.scale().range([0, width])
    const y = d3.time.scale().range([height, 0])

    const xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

    const yAxis = d3.svg.axis()
    .scale(y)
    .orient("left")

    const line = d3.svg.line()
    .x(function(d) { return x(d.date); })
    .y(function(d) { return y(d.close); })

    const data = completedByDate.map((d) => {
      return { date: formatDate.parse(d.completed_date), close: Number(d.respondents) }
    })

    x.domain(d3.extent(data, function(d) { return d.date; }))
    y.domain([0,100])

    svg.append("g")
    .attr("id", "xaxis")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)

    svg.append("g")
    .attr("id", "yaxis")
    .attr("class", "y axis")
    .call(yAxis)

    svg.append("path")
    .attr("id", "pathline")
    .datum(data)
    .attr("class", "line")
    .attr("d", line);

    this.setState({ xAxis: xAxis, yAxis: yAxis, x: x, y: y, width: width, height: height, formatDate: formatDate })
  }

  update(completedByDate){
    const { width, height, formatDate, x, y, xAxis, yAxis } = this.state
    const node = this.state.d3
    const svg = d3.select(node).select("svg")

    const data = completedByDate.map((d) => {
      return { date: formatDate.parse(d.completed_date), close: Number(d.respondents) }
    })

    x.domain(d3.extent(data, function(d) { return d.date; }))
    y.domain(d3.extent(data, function(d) { return d.close; }))

    const line = d3.svg.line()
    .x(function(d) { return x(d.date); })
    .y(function(d) { return y(d.close); })

    svg.select("#xaxis")
    .call(xAxis)

    svg.select("#yaxis")
    .call(yAxis)

    svg.select("#pathline")
    .datum(data)
    .attr("class", "line")
    .attr("d", line);
  }

  render(){
    const { completedByDate } = this.props

    if (!completedByDate) {
      return <div>Loading stats...</div>
    }

    this.update(completedByDate)
    return(
      <div>
        <RD3Component data={this.state.d3}/>
      </div>
    )
  }
}

export default RespondentsChart
