import { photoAccessHelper, PhotoPickerComponent, PickerController, ReminderMode } from '@kit.MediaLibraryKit';
import image from '@ohos.multimedia.image';
import { ImageDataRGBA, ImageTaskRe } from 'type';
import { applyBufferToNewPixelMap, GetRGBAFromPixelMap } from '../utils/helper';
import { taskpool } from '@kit.ArkTS';
import { colorBalance } from '../controller/imageFilters';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { copyImg2Sandbox, pixelMap2File } from '../utils/Utils';
import { BusinessError } from '@kit.BasicServicesKit';


const TAG = 'PIXELMAP_APP';

@Entry({ routeName: 'ImagePicker' })
@ComponentV2
export struct ImagePickerSheet {
  @Local imageUri: string | undefined = undefined;
  @Local imageSource: image.ImageSource | undefined = undefined;
  @Local processing: boolean = false;
  @Local pickerController: PickerController = new PickerController();
  @Local rePixelMap: image.PixelMap | undefined = undefined;
  @Local pixelMap: image.PixelMap | undefined = undefined;
  private sandboxPath: string = this.getUIContext().getHostContext()!.filesDir + '/sandbox_image.jpg';

  onSelect(uri: string): void {
    if (uri) {
      this.imageUri = uri;
    }
  }

  @Builder
  ImageProcess() {
    // Image(this.pixelMap)

    Image(this.rePixelMap)

  }

  async processImage(uri: string) {
    try {
      // 1️⃣ 拷贝图片到沙箱
      await copyImg2Sandbox(uri, this.sandboxPath);
      hilog.info(0x0000, TAG, `Image copied to sandbox: ${this.sandboxPath}`);

      // 2️⃣ 创建 ImageSource
      this.imageSource = image.createImageSource(this.sandboxPath);

      // 3️⃣ 获取 ImageInfo（基本信息）
      this.imageSource.getImageInfo((err: BusinessError, info: image.ImageInfo) => {
        if (err) {
          hilog.error(0x0000, TAG, `getImageInfo failed: ${err.code}, ${err.message}`);
        } else {
          // hilog.info(0x0000, TAG, `ImageInfo: width=${info.width}, height=${info.height}, format=${info.format}`);
        }
      });

      // 4️⃣ 创建 PixelMap
      this.pixelMap = await this.imageSource.createPixelMap();
      hilog.info(0x0000, TAG, `PixelMap created successfully`);

      // 6️⃣ 保存 PixelMap 到沙箱
      await pixelMap2File(this.pixelMap, this.sandboxPath);
      hilog.info(0x0000, TAG, `PixelMap saved to sandbox: ${this.sandboxPath}`);

      const imgData: ImageDataRGBA = await GetRGBAFromPixelMap(this.sandboxPath)

      let loadColorBalance: taskpool.Task =
        new taskpool.Task(colorBalance, imgData.width, imgData.height, imgData.buffer)


      taskpool.execute(loadColorBalance).then(async (res: object) => {
        let reImage = res as ImageTaskRe;
        this.rePixelMap = await applyBufferToNewPixelMap(reImage.width, reImage.height, reImage.out)
      })
      // 7️⃣ 可选：保存到相册

      const context = this.getUIContext().getHostContext();
      if (context) {
        const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
        const assetChangeRequest =
          photoAccessHelper.MediaAssetChangeRequest.createImageAssetRequest(context, this.sandboxPath);
        await phAccessHelper.applyChanges(assetChangeRequest);
        hilog.info(0x0000, TAG, `PixelMap saved to system gallery successfully`);
      }

      this.getUIContext().getPromptAction().showToast({
        message: '图片处理完成并保存成功！',
        duration: 2000
      });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0000, TAG, `processImage failed: ${err.code}, ${err.message}`);
    }
  }

  build() {
    Column({ space: 12 }) {
      Scroll() {
        PhotoPickerComponent({
          pickerOptions: {
            maxPhotoSelectNumber: 1,
            maxVideoSelectNumber: 0,
            maxSelectedReminderMode: ReminderMode.TOAST,
          },
          onSelect: (uri: string) => this.onSelect(uri),
          pickerController: this.pickerController
        })
          .width('100%')
          .height('100%')
      }
      .width('100%')
      .height('90%')

      Column() {
        Button("选择图片")
          .width('100%')
          .height(40)
          .onClick(() => {
            if (this.imageUri) {
              this.processImage(this.imageUri);
            }

            this.processing = true;

          })
      }
      .bindSheet($$this.processing, this.ImageProcess())
      .width('100%')
      .height(40)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .margin({ top: 16, bottom: 44 })
    .justifyContent(FlexAlign.SpaceBetween)

  }
}
