// @flow
import React, { Component } from 'react'
import { translate } from 'react-i18next'

type Props = {
  startIndex: number,
  endIndex: number,
  totalCount: number,
  t: Function,
  onPreviousPage: Function,
  onNextPage: Function
};

class PagingFooterComponent extends Component<Props> {
  previousPage(e) {
    e.preventDefault()
    this.props.onPreviousPage()
  }

  nextPage(e) {
    e.preventDefault()
    this.props.onNextPage()
  }

  render() {
    const { startIndex, endIndex, totalCount, t } = this.props

    return <div className='card-action right-align'>
      <ul className='pagination'>
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
