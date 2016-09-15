import React from 'react'
import { withRouter, Link } from 'react-router'
import Breadcrumbs from 'react-router-breadcrumbs'

export default withRouter(({ routes }) => {
  const breadcrumbSeparator = (crumbElement, index, array) => ""

  const breadcrumbLink = (link, key, text, index, routes) =>
    <Link className="breadcrumb" to={link} key={key}>{text}</Link>

  const logo =
    <div key="0" className="logo">
        <img src='/images/logo.png' width='28px'/>
    </div>

  const breadcrumbPrefix = [logo]

  return (
    <nav id="Breadcrumb">
      <div className="nav-wrapper">
        <div className="row">
            <Breadcrumbs 
              routes={routes}
              createSeparator={breadcrumbSeparator}
              prefixElements = { breadcrumbPrefix }
              createLink={breadcrumbLink}/>
        </div>
      </div>
    </nav>
  )
})