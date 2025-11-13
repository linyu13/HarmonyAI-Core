@ComponentV2
export struct ChatIntroduce {
  @Local titleText: string = ''
  @Local subHeadText: string = ''
  private fullTitle: string = 'Hi , K.'
  private fullSubHead: string = '我是慧影、聊天、搜索、画质增强都在行，助你灵感无限'
  private intervalID: number = 0
  aboutToAppear(): void {
    let titleIndex = 0;
    let subHeadIndex = 0;
    this.intervalID = setInterval(() => {
      if(titleIndex < this.fullTitle.length){
        this.titleText += this.fullTitle.charAt(titleIndex);
        titleIndex++
      }else if(subHeadIndex < this.fullSubHead.length){
        this.subHeadText += this.fullSubHead.charAt(subHeadIndex);
        subHeadIndex++;
      }else{
        clearInterval(this.intervalID);
      }
    },100)
  }
  build() {
    Column({ space: 16 }) {
      Text(this.titleText)
        .fontSize(25)
        .fontWeight(500)
      Text(this.subHeadText)
        .fontSize(14)
        .fontWeight(300)
        .opacity(0.6)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}