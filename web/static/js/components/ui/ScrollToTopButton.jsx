// @flow
import React, { Component } from 'react'

export class ScrollToTopButton extends Component {

  componentDidMount() {
    $(document).ready(function() {
      $(window).scroll(function () {
        if ($(this).scrollTop() > 500) {
            $('.scrollToTop').fadeIn()
        } else {
            $('.scrollToTop').fadeOut()
        }
      })
    })
  }

  constructor(props){
    super(props)

    this.topScrollTo = this.topScrollTo.bind(this)
  }

  topScrollTo(e) {
    e.preventDefault()
    scrollToTop()
  }

  render() {
    return <a href='' title='Back to top' className='scrollToTop' onClick={this.topScrollTo}>
    <i className='material-icons'>arrow_upward</i>
    </a>
  }
}


const scrollToTop = () => {
  if(window.scrollY>0) {
    setTimeout(function() {
       window.scrollTo(0,window.scrollY-35)
        scrollToTop()
    }, 0)
  }
}

