import React, { Component, PropTypes } from "react"
import { withRouter } from "react-router"
import { Title } from "../ui"

class TitleContainer extends Component {
  render() {
    const { routes } = this.props

    // Find the last element in the route path having a `title` attribute
    let title = ""
    for (var i = routes.length - 1; i >= 0; i--) {
      if (routes[i].title) {
        title = routes[i].title
        break
      }
    }

    if (typeof title == "function") {
      const TitleClass = title
      return (
        <Title>
          <TitleClass />
        </Title>
      )
    } else {
      return <Title>{title}</Title>
    }
  }
}

TitleContainer.propTypes = {
  routes: PropTypes.any,
}

export default withRouter(TitleContainer)
