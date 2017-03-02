import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/step'
import * as api from '../api'

class Step extends Component {
  componentDidMount() {
    const { dispatch } = this.props

    api.fetchStep().then(response => {
      response.json().then(json => {
        dispatch(actions.receiveStep(json.step))
      })
    })
  }

  render() {
    const { step } = this.props
    if (!step) {
      return <div>Loading...</div>
    }

    return (
      <div>{step.type} step</div>
    )
  }
}

Step.propTypes = {
  dispatch: PropTypes.any,
  step: PropTypes.object
}

const mapStateToProps = (state) => ({
  step: state.step.current
})

export default connect(mapStateToProps)(Step)

