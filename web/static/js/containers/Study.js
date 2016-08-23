import React, { Component, PropTypes } from 'react'
//import { connect } from 'react-redux'
//import { v4 } from 'node-uuid'

export default class Study extends Component {
  render() {
    const { study } = this.props
    return (
      <tr>
        <td>  
          <a href="#">{ study.name }</a>
        </td>
      </tr>
    )
  }
}
