@ComponentV2
struct testView {
  @Local response: string = ''
  @Local request: string = ''

  build() {
    Column() {
      Column({ space: 16 }) {
        Row({ space: 5 }) {
          TextInput()
            .onChange((res) => {
              this.request = res;
            })
            .layoutWeight(1)
          Button('发送')
            .width(100)

        }
        .width('100%')

        Row() {
          Text(this.response)
        }
        .width('100%')

        //MainPage({ dataPreferences: dataPreferences_, getRdbStore: getRdbStore })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.Center)
    }
  }
}