import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';
import { IMessage } from 'type';

@ComponentV2
export struct ChatMessageItem {
  @Require @Param meg: IMessage
  @Require @Param mdControlUser: MarkdownController 
  @Require @Param mdControlAi: MarkdownController
  private isUser: boolean = false;
  aboutToAppear(): void {
    this.isUser = (this.meg.role == 'user');
  }

  build() {
    Row() {
      Row(){
        Markdown({
          text: (this.meg.content as string) ?? '',
          controller: this.isUser? this.mdControlUser : this.mdControlAi
        })
      }
      .backgroundColor(this.isUser? '#00b4ff' : '#f7f7f7')
      .borderRadius(14)
      .padding(10)
    }
    .width('100%')
    .justifyContent(this.isUser? FlexAlign.End : FlexAlign.Start)
  }
}