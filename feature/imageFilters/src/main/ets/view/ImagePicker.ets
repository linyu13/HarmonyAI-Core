import { image } from '@kit.ImageKit';
import { photoAccessHelper, PhotoPickerComponent, PickerController, ReminderMode } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { copyImg2Sandbox, pixelMap2File } from '../utils/Utils';
import { taskpool } from '@kit.ArkTS';
import { ImageDataRGBA, ImageTaskRe } from 'type';
import { applyBufferToNewPixelMap, GetRGBAFromPixelMap } from '../utils/helper';
import { colorBalance } from '../controller/imageFilters';


const TAG = 'PIXELMAP_APP';

@ComponentV2
export struct ImagePickerSheet {
  @Local pickerController: PickerController = new PickerController();
  @Local isShowGet: boolean = false;
  @Local isShowPicker: boolean = true;
  private sandboxPath: string = this.getUIContext().getHostContext()!.filesDir + '/sandbox_image.jpg';

  @Builder
  photoPicker() {
    Column({ space: 12 }) {
      Scroll() {
        PhotoPickerComponent({
          pickerOptions: {
            maxPhotoSelectNumber: 1,
            maxVideoSelectNumber: 0,
            maxSelectedReminderMode: ReminderMode.TOAST,
          },
          onSelect: (uri: string): Promise<void> => this.onSelect(uri),
          pickerController: this.pickerController
        })
          .width('100%')
          .height('100%')
      }
      .width('100%')
      .height(400)

      Column() {
        Button("确认")
          .width('100%')
          .height(40)
          .onClick(() => {
            this.isShowPicker = false;
            this.isShowGet = false;
          })
      }
      .width('100%')
      .height(40)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(452)
    .margin({ top: 16, bottom: 44 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  async onSelect(uri: string) {
    if (uri) {
      await copyImg2Sandbox(uri, this.sandboxPath);
      this.isShowPicker = false;
    }
  }

  build() {

  }
}
