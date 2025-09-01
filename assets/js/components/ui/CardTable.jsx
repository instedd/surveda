import React, { PropTypes } from "react"
import classNames from "classnames/bind"

export const CardTable = ({
  title,
  children,
  className,
  footer,
  highlight = false,
  tableScroll = false,
  style,
}) => (
  <div className="row">
    <div className="col s12">
      <div
        className={classNames(className, {
          card: true,
          tableScroll: tableScroll,
        })}
      >
        { title ? <div className="card-table-title">{title}</div> : null }
        <div className="card-table">
          <table className={classNames(className, { highlight: highlight })} style={style}>
            {children}
          </table>
        </div>
        {footer}
      </div>
    </div>
  </div>
)

CardTable.propTypes = {
  title: PropTypes.node,
  highlight: PropTypes.bool,
  tableScroll: PropTypes.bool,
  children: PropTypes.node,
  footer: PropTypes.object,
  className: PropTypes.string,
  style: PropTypes.object,
}
