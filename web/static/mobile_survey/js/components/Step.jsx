import React, { Component, PropTypes } from 'react'
import 'isomorphic-fetch'
import { Provider } from 'react-redux'
// import routes from '../../routes'
// import { Router } from 'react-router'

export default class Step extends Component {
  static propTypes = {
    step: PropTypes.object.isRequired
    // history: PropTypes.object.isRequired
  }

  componentWillMount() {

  }

  render() {
    const { store, history } = this.props
    return (
      <div />
    )
  }

}
