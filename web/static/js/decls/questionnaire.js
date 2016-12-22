// @flow
export type Questionnaire = {
  name: string,
  steps: Step[],
  modes: string[],
  languages: string[],
  defaultLanguage: string,
  quotaCompletedMsg: ?Prompt,
  errorMsg: ?Prompt,
};

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

export type MultipleChoiceStep = BaseStep & {
  type: 'multiple-choice',
  choices: Choice[]
};

export type LanguageSelectionStep = BaseStep & {
  type: 'language-selection',
  languageChoices: (?string)[]
};

export type NumericStep = BaseStep & {
  type: 'numeric',
  minValue: ?number,
  maxValue: ?number,
  rangesDelimiters: ?string,
  ranges: Range[]
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

export type Step = LanguageSelectionStep | MultipleChoiceStep | NumericStep;
export type BaseStep = {
  id: string,
  title: string,
  store: string,
  prompt: Prompt
};

export type SkipOption = {
  id: string,
  title: string
};
