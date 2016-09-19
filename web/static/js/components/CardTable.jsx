import React from 'react'

export default ({ title, children }) => (
  <div className="row">
    <div className="col s12">
      <div className="card">
        <div className="card-table-title">
          { title }
        </div>
        <div className="card-table">
          <table>
            { children }
          </table>
        </div>
      </div>
    </div>
  </div>
)
