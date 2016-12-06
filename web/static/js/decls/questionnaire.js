// @flow
export type Questionnaire = {
  name: string,
  steps: Step[],
  modes: string[],
  languages: string[],
  defaultLanguage: string
};

export type AudioPrompt = {
    audioSource: 'tts' | 'upload',
    text: string,
    audioId?: ?string
};

export type LanguagePrompt = {
  sms: string,
  ivr: AudioPrompt,
};

export type Prompt = { [lang: string]: LanguagePrompt };

export type MultipleChoiceStep = {
  id: string,
  type: 'multiple-choice',
  title: string,
  store: string,
  prompt: Prompt,
  choices: Choice[]
};

export type LanguageSelectionStep = {
  id: string,
  type: 'language-selection',
  title: string,
  store: string,
  prompt: Prompt,
  languageChoices: (?string)[]
}

export type Choice = {
  value: string,
  skipLogic: ?string,
  responses: {
    [lang: string]: {
      sms: string[],
      ivr: string[]
    }
  }
};

type Step = MultipleChoiceStep | LanguageSelectionStep;
