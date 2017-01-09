// @flow
export type Questionnaire = {
  name: string,
  steps: Step[],
  modes: string[],
  languages: string[],
  defaultLanguage: string,
  activeLanguage: string,
  quotaCompletedMsg: ?Prompt,
  errorMsg: ?Prompt,
  projectId: number
};

export type ChoiceErrors = {
  value: string[],
  sms: string[],
  ivr: string[]
}

export type AudioPrompt = {
    audioSource: 'tts' | 'upload',
    text: string,
    audioId?: ?string
};

export type LanguagePrompt = {
  sms?: string,
  ivr?: AudioPrompt,
};

export type Prompt = { [lang: string]: LanguagePrompt };

export type MultipleChoiceStep = BaseStep & StoreStep & MultilingualStep & {
  type: 'multiple-choice',
  choices: Choice[]
};

export type LanguageSelectionStep = BaseStep & StoreStep & {
  type: 'language-selection',
  languageChoices: (?string)[],
  prompt: LanguagePrompt
};

export type ExplanationStep = BaseStep & MultilingualStep & {
  type: 'explanation',
  skipLogic: ?string
};

export type NumericStep = BaseStep & StoreStep & MultilingualStep & {
  type: 'numeric',
  minValue: ?number,
  maxValue: ?number,
  rangesDelimiters: ?string,
  ranges: Range[],
};

export type Range = {
  from: ?number,
  to: ?number,
  skipLogic: ?string
};

export type Choice = {
  value: string,
  skipLogic: ?string,
  responses: {
    ivr?: string[],
    sms?: {
      [lang: string]: string[]
    }
  }
};

export type Step = LanguageSelectionStep | MultipleChoiceStep | NumericStep | ExplanationStep;
export type BaseStep = {
  id: string,
  title: string
};

export type StoreStep = {
  store: string
}

export type MultilingualStep = {
  prompt: Prompt
}

export type SkipOption = {
  id: string,
  title: string,
  enabled: boolean
};

export type Translation = {
  text: string,
  language: string
};

export type AutocompleteItem = {
  id: string,
  text: string,
  translations: Translation[]
};
