// @flow
import React, { Component, PropTypes } from 'react'
import Prompt from '../Prompt'

class MultipleChoiceStep extends Component {
  getValue() {
    return this.refs.select.value
  }

  classNameForChoice(choice: String) {
    const length = choice.length
    let cssClass
    switch (true) {
      case (length < 4):
        cssClass = 'choice-length-less-7'
        break
      case (length < 12):
        cssClass = 'choice-length-less-14'
        break
      case (length < 20):
        cssClass = 'choice-length-less-20'
        break
      case (length < 40):
        cssClass = 'choice-length-less-40'
        break
      case (length < 60):
        cssClass = 'choice-length-less-60'
        break
      default:
        cssClass = 'choice-length-large'
    }
    return cssClass
  }

  meanFromChoice(selectedChoice: HTMLElement) {
    const bounds = selectedChoice.getBoundingClientRect()
    return (bounds.bottom + bounds.top) / 2
  }

  adjustPixels(prompt: HTMLElement, difference: number) {
    const promptMarginBottom = (window.getComputedStyle(prompt)).marginBottom
    const pixels = parseFloat(promptMarginBottom) + difference
    prompt.style.marginBottom = pixels.toString() + 'px'
  }

  componentDidMount() {
    const screenHeight = screen.height
    const choices = document.getElementsByClassName('choice')
    let selectedChoice

    for (var i = 0; i < choices.length; i++) {
      const bounds = (choices[i]).getBoundingClientRect()
      const prompt = (document.getElementsByClassName('prompt')[0])
      // When bottom of screen matches one of the buttons, prompt margin is
      // adjusted in order to match the middle of that button
      if (bounds.top <= screenHeight && bounds.bottom >= screenHeight) {
        selectedChoice = choices[i]
        const mean = this.meanFromChoice(selectedChoice)
        const difference = screenHeight - mean
        this.adjustPixels(prompt, difference)
      } else {
        // When bottom of screen matches none of the buttons, the previous button
        // that exceeds the screen height is selected to adjust the prompt margin
        if (bounds.top > screenHeight && i > 0 && (choices[i - 1].getBoundingClientRect()).top < screenHeight) {
          selectedChoice = choices[i - 1]
          const mean = this.meanFromChoice(selectedChoice)
          const difference = screenHeight - mean
          this.adjustPixels(prompt, difference)
        }
      }
    }
  }

  render() {
    const { step, onClick } = this.props
    return (
      <div>
        {(step.prompts || []).map(prompt =>
          <Prompt key={prompt} text={prompt} />
        )}
        {step.choices.map(choice => {
          return (
            <div key={choice} className='choice'>
              <button className={'btn block ' + this.classNameForChoice(choice[0])} value={choice} onClick={e => { e.preventDefault(); onClick(choice) }}>{choice}</button>
            </div>
          )
        })}
      </div>
    )
  }
}

MultipleChoiceStep.propTypes = {
  step: PropTypes.object,
  onClick: PropTypes.func
}

export default MultipleChoiceStep
