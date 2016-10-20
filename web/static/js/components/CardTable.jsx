import React from 'react'

export default ({ title, children, footer, highlight }) => (
  <div className='row'>
    <div className='col s12'>
      <div className='card'>
        <div className='card-table-title'>
          { title }
        </div>
        <div className='card-table'>
          <table className={`${highlight ? 'highlight' : ''}`}>
            { children }
          </table>
          { footer }
        </div>
      </div>
    </div>
  </div>
)
