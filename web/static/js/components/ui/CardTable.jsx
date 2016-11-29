import React, { PropTypes } from 'react'

export const CardTable = ({ title, children, footer, highlight, style }) => (
  <div className='row'>
    <div className='col s12'>
      <div className='card'>
        <div className='card-table-title'>
          { title }
        </div>
        <div className='card-table'>
          <table className={`${highlight ? 'highlight' : ''}`} style={style}>
            { children }
          </table>
          { footer }
        </div>
      </div>
    </div>
  </div>
)

CardTable.propTypes = {
  title: PropTypes.node.isRequired,
  highlight: PropTypes.bool,
  children: PropTypes.node,
  footer: PropTypes.object,
  style: PropTypes.object
}
