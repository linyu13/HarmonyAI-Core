import {ChatCompletionMessageParam,ChatCompletionSystemMessageParam,
ChatCompletionUserMessageParam,ChatCompletionAssistantMessageParam} from '@iuroc/openai/src/main/ets/openai@4.73.1/resources/chat/completions'
type IMessage = ChatCompletionMessageParam;
type SystemMessage = ChatCompletionSystemMessageParam;
type UserMessage = ChatCompletionUserMessageParam;
type AiMessage = ChatCompletionAssistantMessageParam;
export {IMessage,SystemMessage,UserMessage,AiMessage}