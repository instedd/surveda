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
    const { completedByDate } = this.props

    const node = document.createElement('div')

    const margin = {top: 20, right: 20, bottom: 30, left: 50}
    const width = 960 - margin.left - margin.right
    const height = 500 - margin.top - margin.bottom

    const svg = d3.select(node).append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

    this.setState({d3: node})
    this.create([], node)
  }

  create(completedByDate, node){
    const margin = {top: 20, right: 20, bottom: 30, left: 50}
    const width = 960 - margin.left - margin.right
    const height = 500 - margin.top - margin.bottom

    const svg = d3.select(node).select("svg")

    const formatDate = d3.time.format("%d-%b-%y")

    const x = d3.time.scale().range([0, width])

    const y = d3.scale.linear().range([height, 0]);

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
    y.domain(d3.extent(data, function(d) { return d.close; }))

    svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)

    svg.append("g")
    .attr("class", "y axis")
    .call(yAxis)
    .append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", 6)
    .attr("dy", ".71em")
    .style("text-anchor", "end")
    .text("Price ($)")

    svg.append("path")
    .attr("id", "pepe")
    .datum(data)
    .attr("class", "line")
    .attr("d", line);
  }

  update(completedByDate){
    const margin = {top: 20, right: 20, bottom: 30, left: 50}
    const width = 960 - margin.left - margin.right
    const height = 500 - margin.top - margin.bottom

    const node = this.state.d3
    const svg = d3.select(node).select("svg")

    const formatDate = d3.time.format("%d-%b-%y")

    const x = d3.time.scale().range([0, width])

    const y = d3.scale.linear().range([height, 0]);

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
    y.domain(d3.extent(data, function(d) { return d.close; }))

    svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)

    svg.append("g")
    .attr("class", "y axis")
    .call(yAxis)
    .append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", 6)
    .attr("dy", ".71em")
    .style("text-anchor", "end")
    .text("Price ($)")

    svg.select("#pepe")
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
