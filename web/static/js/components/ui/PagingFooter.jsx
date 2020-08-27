// @flow
import React, { Component } from 'react'
import { Input } from 'react-materialize'
import { translate } from 'react-i18next'
import { uniqueId } from 'lodash'

type Props = {
  startIndex: number,
  endIndex: number,
  totalCount: number,
  t: Function,
  onPreviousPage: Function,
  onNextPage: Function,
  onPageSizeChange: Function,
  pageSize: number
};

class PagingFooterComponent extends Component<Props> {
  pageSizeSelectId: string

  constructor(props) {
    super(props)
    this.pageSizeSelectId = uniqueId('page-size-select-id')
  }

  previousPage(e) {
    e.preventDefault()
    this.props.onPreviousPage()
  }

  nextPage(e) {
    e.preventDefault()
    this.props.onNextPage()
  }

  renderPageSize() {
    const { pageSize, onPageSizeChange, t } = this.props
    const onChange = event => {
      const pageSize = parseInt(event.target.value)
      onPageSizeChange(pageSize)
    }
    const sizeOptions = [ 5, 10, 20, 50 ]
    return (
      <li className='page-size'>
        <div className='valign-wrapper'>
          <label htmlFor={this.pageSizeSelectId}>{t('Rows per page:')}</label>
          <Input id={this.pageSizeSelectId} type='select' value={pageSize} onChange={onChange}>
            {
              sizeOptions.map((size, index) => (
                <option value={size} key={index}>{size}</option>
              ))
            }
          </Input>
        </div>
      </li>
    )
  }

  render() {
    const { startIndex, endIndex, totalCount, t } = this.props
    return <div className='card-action right-align'>
      <ul className='pagination'>
        {this.renderPageSize()}
        <li className='page-numbers'>{t('{{startIndex}}-{{endIndex}} of {{totalCount}}', {startIndex: totalCount ? startIndex : 0, endIndex, totalCount})}</li>
        { startIndex > 1
            ? <li className='previous-page'><a href='#!' onClick={e => this.previousPage(e)}><i className='material-icons'>chevron_left</i></a></li>
            : <li className='disabled previous-page'><i className='material-icons'>chevron_left</i></li>
          }
        { endIndex < totalCount
            ? <li className='next-page'><a href='#!' onClick={e => this.nextPage(e)}><i className='material-icons'>chevron_right</i></a></li>
            : <li className='disabled next-page'><i className='material-icons'>chevron_right</i></li>
          }
      </ul>
    </div>
  }
}

export const PagingFooter = translate()(PagingFooterComponent)
