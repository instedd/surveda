import React from 'react'

export default ({ title, children }) => (
  <div className="col s12 m6 l4">
    <div className="card white">
      <div className="card-content">
        <span className="card-title">
          { title }
        </span>
      </div>
      <div className="card-action">
        { children }
      </div>
    </div>
  </div>
)
