// @flow
export function getStepPrompt(step: Step, language: string): LanguagePrompt {
  let prompt = null
  if (step.type !== 'flag') {
    if (step.type === 'language-selection') {
      prompt = step.prompt
    } else {
      prompt = step.prompt[language]
    }
  }
  return prompt || newStepPrompt()
}

export function setStepPrompt<T: Step>(step: T, language: string, func: (prompt: Object) => T): T {
  let prompt = getStepPrompt(step, language) || newStepPrompt()
  prompt = func(prompt)
  let newStep
  if (step.type === 'language-selection') {
    newStep = {
      ...step,
      prompt
    }
  } else {
    if (step.type !== 'flag') {
      newStep = {
        ...step,
        prompt: {
          ...step.prompt,
          [language]: prompt
        }
      }
    } else {
      newStep = step
    }
  }
  return ((newStep: any): T)
}

export function getStepPromptSms(step: Step, language: string): string {
  return ((getStepPrompt(step, language) || {}).sms || '').trim()
}

export function getStepPromptMobileWeb(step: Step, language: string): string {
  return ((getStepPrompt(step, language) || {}).mobileweb || '').trim()
}

export function getStepPromptIvr(step: Step, language: string): AudioPrompt {
  return (getStepPrompt(step, language) || {}).ivr || {audioSource: 'tts', text: ''}
}

export function getStepPromptIvrText(step: Step, language: string): string {
  return (getStepPromptIvr(step, language).text || '').trim()
}

export function getPromptSms(prompt: ?Prompt, language: string): string {
  return (((prompt || {})[language] || {}).sms || '').trim()
}

export function getPromptMobileWeb(prompt: ?Prompt, language: string): string {
  return (((prompt || {})[language] || {}).mobileweb || '').trim()
}

export function getPromptIvr(prompt: ?Prompt, language: string): AudioPrompt {
  return ((prompt || {})[language] || {}).ivr || {audioSource: 'tts', text: ''}
}

export function getPromptIvrText(prompt: ?Prompt, language: string): string {
  return (getPromptIvr(prompt, language).text || '').trim()
}

export function getChoiceResponseSmsJoined(choice: Choice, language: string): string {
  return ((choice.responses.sms || {})[language] || []).join(', ')
}

export function getChoiceResponseIvrJoined(choice: Choice): string {
  return (choice.responses.ivr || []).join(', ')
}

export function getChoiceResponseMobileWebJoined(choice: Choice, language: string): string {
  return (choice.responses.mobileweb || {})[language] || ''
}

export const newStepPrompt = () => {
  return {
    sms: '',
    ivr: newIvrPrompt(),
    mobileweb: ''
  }
}

export const newIvrPrompt = () => ({
  text: '',
  audioSource: 'tts'
})

export const newRefusal = () => ({
  enabled: false,
  responses: {
    ivr: [],
    sms: {
      'en': []
    }
  },
  skipLogic: null
})

export const splitSmsText = (string: string): string[] => {
  return string.split(smsSplitSeparator)
}

export const joinSmsPieces = (pieces: string[]): string => {
  return pieces.join(smsSplitSeparator)
}

export const containsSeparator = (text: string): boolean => {
  return text.includes(smsSplitSeparator)
}

export const smsSplitSeparator = '\u001E'
