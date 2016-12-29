// @flow
export function getStepPrompt(step: Step, language: string): LanguagePrompt {
  if (step.type === 'language-selection') {
    return step.prompt
  } else {
    return step.prompt[language]
  }
}

export function setStepPrompt<T: Step>(step: T, language: string, func: (prompt: Object) => T): T {
  let prompt = getStepPrompt(step, language) || newStepPrompt()
  prompt = func(prompt)
  let newStep
  if (step.type == 'language-selection') {
    newStep = {
      ...step,
      prompt
    }
  } else {
    newStep = {
      ...step,
      prompt: {
        ...step.prompt,
        [language]: prompt
      }
    }
  }
  return ((newStep: any): T)
}

export function getStepPromptSms(step: Step, language: string): string {
  return ((getStepPrompt(step, language) || {}).sms || '').trim()
}

export function getStepPromptIvr(step: Step, language: string): any {
  return (getStepPrompt(step, language) || {}).ivr || {}
}

export function getStepPromptIvrText(step: Step, language: string): string {
  return (getStepPromptIvr(step, language).text || '').trim()
}

export function getPromptSms(prompt: ?Prompt, language: string): string {
  return (((prompt || {})[language] || {}).sms || '').trim()
}

export function getPromptIvr(prompt: ?Prompt, language: string): any {
  return ((prompt || {})[language] || {}).ivr || {}
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

export const newStepPrompt = () => {
  return {
    sms: '',
    ivr: {
      text: '',
      audioSource: 'tts'
    }
  }
}
