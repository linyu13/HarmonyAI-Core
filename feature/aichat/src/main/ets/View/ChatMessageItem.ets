import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';

@ComponentV2
export struct ChatMessageItem {
  @Param content: string = ''
  @Require @Param isUser: boolean
  private controller: MarkdownController = new MarkdownController();

  aboutToAppear(): void {
    if (this.isUser) {
      this.controller
        .setTextColor(Color.White)
    } else {
      this.controller
        .setTextColor(Color.Black)
    }
  }

  build() {
    Column() {
      Markdown({
        text: this.content,
        controller: this.controller
      })
    }
    .backgroundColor(this.isUser ? Color.Blue : Color.Gray)
  }
}