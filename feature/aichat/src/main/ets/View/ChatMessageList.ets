import { MarkdownController } from "@luvi/lv-markdown-in"
import { IMessage, IObserver } from "type"
import { BaseDataSource } from "utils"
import { ChatDateSource } from "../model/ChatDateSource"
import { ChatMessageItem } from "./ChatMessageItem"
import { ChatObserver } from "./ChatObserver"
import { window } from "@kit.ArkUI"
import { BusinessError } from "@kit.BasicServicesKit"

@ComponentV2
export struct ChatMessageList{
  @Local curResponse: string = ''
  @Require @Param scrollerControl: Scroller
  @Require @Param dataSource: BaseDataSource<IMessage>
  private isEnd: boolean = true;
  private mdControlUser: MarkdownController = new MarkdownController()
  private mdControlAi: MarkdownController = new MarkdownController()

  private keyBoardCallBack = (info: window.KeyboardInfo) =>{
    if(this.isEnd){
      this.scrollerControl.scrollTo({
        xOffset:0,
        yOffset:info.beginRect.height,
        animation:{duration: 500,curve: Curve.Ease,canOverScroll: false}
      })
    }else{
      console.log('')
    }
  }
  aboutToAppear(): void {
    this.mdControlInit();
    this.onKeyBoardStart();
  }
  mdControlInit(){
    this.mdControlUser.setTextColor(Color.White);
    this.mdControlUser.setTextSize(18)
    this.mdControlAi.setTextColor(Color.Black);
    this.mdControlAi.setTextSize(18)
  }
  onKeyBoardStart(){
    window.getLastWindow(getContext(this))
      .then((curWindow) => {
        curWindow.on('keyboardWillShow',this.keyBoardCallBack)
      })
      .catch((err: BusinessError) => {
        console.log('[onKeyBoardStart]'+err.message)
      })
  }
  build() {
    WaterFlow({scroller: this.scrollerControl}){
      LazyForEach(this.dataSource,(item: IMessage,index: number) => {
        ChatMessageItem({
          meg: item,
          mdControlUser: this.mdControlUser,
          mdControlAi: this.mdControlAi
        })
      },(item: string) => JSON.stringify(item))
    }
    .rowsGap(16)
    .cachedCount(5)
    .onScrollStop(() => {
      this.isEnd = this.scrollerControl.isAtEnd();
    })
  }
}