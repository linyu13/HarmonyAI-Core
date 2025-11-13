import { ImageTaskRe } from 'type';
import { clampToU8, makeGaussianKernel1D, rgbaToGrayUint8 } from '../utils/helper';

/**
 * 1. Histogram Equalization（每通道分别均衡）
 * 原理：计算每个通道的直方图及累积分布函数(CDF)，并用 CDF 将像素映射到新的强度值
 */
export async function histogramEqualization(width: number, height: number, buffer: Uint8Array,
  grayMode: boolean = false,
  strength: number = 0.6): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);

  if (grayMode) {
    // 灰度化后均衡
    const gray = rgbaToGrayUint8(buffer, width, height);
    const hist: number[] = new Array<number>(256).fill(0);
    for (let i = 0; i < n; i++) {
      hist[gray[i]]++;
    }
    const cdf: number[] = new Array<number>(256).fill(0);
    cdf[0] = hist[0];
    for (let i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + hist[i];
    }
    const cdfMin = cdf.find(v => v > 0) ?? 0;
    const denom = (n - cdfMin) || 1;

    for (let i = 0; i < n; i++) {
      const newGray = ((cdf[gray[i]] - cdfMin) / denom) * 255;
      const finalGray = gray[i] * (1 - strength) + newGray * strength;
      out[i * 4] = out[i * 4 + 1] = out[i * 4 + 2] = clampToU8(finalGray);
      out[i * 4 + 3] = buffer[i * 4 + 3];
    }
  } else {
    // RGB 分通道均衡
    for (let c = 0; c < 3; c++) {
      const hist: number[] = new Array<number>(256).fill(0);
      for (let i = 0; i < n; i++) {
        hist[buffer[i * 4 + c]]++;
      }
      const cdf: number[] = new Array<number>(256).fill(0);
      cdf[0] = hist[0];
      for (let i = 1; i < 256; i++) {
        cdf[i] = cdf[i - 1] + hist[i];
      }
      const cdfMin = cdf.find(v => v > 0) ?? 0;
      const denom = (n - cdfMin) || 1;
      for (let i = 0; i < n; i++) {
        const v = buffer[i * 4 + c];
        const newVal = ((cdf[v] - cdfMin) / denom) * 255;
        out[i * 4 + c] = clampToU8(v * (1 - strength) + newVal * strength);
      }
    }
    for (let i = 0; i < n; i++) {
      out[i * 4 + 3] = buffer[i * 4 + 3];
    }
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 2. Contrast Stretching（线性对比度拉伸，每通道）
 * 原理：将每个通道的最小/最大值线性映射到 0..255
 */

export async function contrastStretching(width: number, height: number, buffer: Uint8Array): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);

  for (let c = 0; c < 3; c++) {
    let mn = 255, mx = 0;
    for (let i = 0; i < n; i++) {
      const v = buffer[i * 4 + c];
      if (v < mn) {
        mn = v;
      }
      if (v > mx) {
        mx = v;
      }
    }
    const denom = (mx - mn) || 1;
    for (let i = 0; i < n; i++) {
      out[i * 4 + c] = clampToU8(((buffer[i * 4 + c] - mn) / denom) * 255);
    }
  }
  for (let i = 0; i < n; i++) {
    out[i * 4 + 3] = buffer[i * 4 + 3];
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 3. Gamma Correction
 * 原理：使用指数映射调整亮度： out = 255 * (in/255)^(1/gamma)
 */
export async function gammaCorrection(width: number, height: number, buffer: Uint8Array,
  gamma: number = 1.1): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);
  const inv = 1.0 / gamma;
  const lut = new Uint8Array(256);
  for (let i = 0; i < 256; i++) {
    lut[i] = clampToU8(255 * Math.pow(i / 255, inv));
  }

  for (let i = 0; i < n; i++) {
    out[i * 4] = lut[buffer[i * 4]];
    out[i * 4 + 1] = lut[buffer[i * 4 + 1]];
    out[i * 4 + 2] = lut[buffer[i * 4 + 2]];
    out[i * 4 + 3] = buffer[i * 4 + 3];
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 4. Mean Filter（均值滤波）
 * 原理：对每个像素取邻域平均以平滑图像
 */
export async function meanFilter(width: number, height: number, buffer: Uint8Array,
  kernelSize: number = 3): Promise<ImageTaskRe> {

  const channelCount = 3; // 只处理 RGB 通道（忽略 alpha，最后直接复制）

  // 确保核大小为奇数（均值滤波通常使用奇数核）
  if (kernelSize % 2 === 0) {
    kernelSize++;
  }
  const half = Math.floor(kernelSize / 2);
  if (kernelSize < 3) {
    kernelSize = 3;
  } // 最小核大小为 3x3

  // 1. 行方向滤波：计算水平方向的滑动窗口均值
  const rowBuffer = new Uint8Array(buffer.length); // 行滤波中间结果
  for (let c = 0; c < channelCount; c++) { // 按通道处理（R、G、B）
    for (let y = 0; y < height; y++) { // 按行处理
      let sum = 0;
      let count = 0;

      // 初始化第一个窗口（左边界）
      for (let kx = 0; kx <= half; kx++) {
        const xx = kx; // x从0开始，左边界窗口只取到x=half
        sum += buffer[(y * width + xx) * 4 + c];
        count++;
      }
      rowBuffer[(y * width + 0) * 4 + c] = clampToU8(sum / count);

      // 滑动窗口处理剩余x（从1到width-1）
      for (let x = 1; x < width; x++) {
        // 移除窗口左侧离开的像素（x - half - 1）
        const leftX = x - half - 1;
        if (leftX >= 0) {
          sum -= buffer[(y * width + leftX) * 4 + c];
          count--;
        }
        // 加入窗口右侧新进入的像素（x + half）
        const rightX = x + half;
        if (rightX < width) {
          sum += buffer[(y * width + rightX) * 4 + c];
          count++;
        }
        // 计算当前x的行滤波结果
        rowBuffer[(y * width + x) * 4 + c] = clampToU8(sum / count);
      }
    }
  }

  // 2. 列方向滤波：基于行结果计算垂直方向的滑动窗口均值
  const outBuffer = new Uint8Array(buffer.length); // 最终结果
  for (let c = 0; c < channelCount; c++) { // 按通道处理
    for (let x = 0; x < width; x++) { // 按列处理
      let sum = 0;
      let count = 0;

      // 初始化第一个窗口（上边界）
      for (let ky = 0; ky <= half; ky++) {
        const yy = ky; // y从0开始，上边界窗口只取到y=half
        sum += rowBuffer[(yy * width + x) * 4 + c];
        count++;
      }
      outBuffer[(0 * width + x) * 4 + c] = clampToU8(sum / count);

      // 滑动窗口处理剩余y（从1到height-1）
      for (let y = 1; y < height; y++) {
        // 移除窗口上侧离开的像素（y - half - 1）
        const topY = y - half - 1;
        if (topY >= 0) {
          sum -= rowBuffer[(topY * width + x) * 4 + c];
          count--;
        }
        // 加入窗口下侧新进入的像素（y + half）
        const bottomY = y + half;
        if (bottomY < height) {
          sum += rowBuffer[(bottomY * width + x) * 4 + c];
          count++;
        }
        // 计算当前y的最终结果
        outBuffer[(y * width + x) * 4 + c] = clampToU8(sum / count);
      }
    }
  }

  // 复制alpha通道（不参与滤波）
  for (let i = 3; i < buffer.length; i += 4) {
    outBuffer[i] = buffer[i];
  }

  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: outBuffer
  }
  return re;
}

// 多线程解决
/**
 * 5. Median Filter（中值滤波）
 * 原理：取邻域像素的中位数，擅长去除椒盐噪声
 */
export async function medianFilter(width: number, height: number, buffer: Uint8Array,
  kernelSize: number): Promise<ImageTaskRe> {

  const out = new Uint8Array(buffer.length);
  const half = Math.floor(kernelSize / 2);
  const win: number[] = [];

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      for (let c = 0; c < 3; c++) {
        win.length = 0;
        for (let ky = -half; ky <= half; ky++) {
          const yy = y + ky;
          if (yy < 0 || yy >= height) {
            continue;
          }
          for (let kx = -half; kx <= half; kx++) {
            const xx = x + kx;
            if (xx < 0 || xx >= width) {
              continue;
            }
            win.push(buffer[(yy * width + xx) * 4 + c]);
          }
        }
        win.sort((a, b) => a - b);
        out[(y * width + x) * 4 + c] = win[Math.floor(win.length / 2)];
      }
      out[(y * width + x) * 4 + 3] = buffer[(y * width + x) * 4 + 3];
    }
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 6. Gaussian Blur（可分离卷积实现）
 * 原理：使用高斯核对图像进行平滑；为了效率采用可分离的 1D 卷积（先横向再纵向）
 */
export async function gaussianBlur(width: number, height: number, buffer: Uint8Array,
  sigma: number): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);
  const GeneratedDestructObj_1 = makeGaussianKernel1D(sigma);
  const kernel = GeneratedDestructObj_1.kernel;
  const radius = GeneratedDestructObj_1.radius;

  // 横向卷积到临时浮点 buffer（每像素 3 通道）
  const temp = new Float32Array(width * height * 3);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      for (let c = 0; c < 3; c++) {
        let sum = 0;
        for (let k = -radius; k <= radius; k++) {
          const xx = Math.min(width - 1, Math.max(0, x + k));
          sum += buffer[(y * width + xx) * 4 + c] * kernel[k + radius];
        }
        temp[(y * width + x) * 3 + c] = sum;
      }
    }
  }

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      for (let c = 0; c < 3; c++) {
        let sum = 0;
        for (let k = -radius; k <= radius; k++) {
          const yy = Math.min(height - 1, Math.max(0, y + k));
          sum += temp[(yy * width + x) * 3 + c] * kernel[k + radius];
        }
        out[(y * width + x) * 4 + c] = clampToU8(sum);
      }
      out[(y * width + x) * 4 + 3] = buffer[(y * width + x) * 4 + 3];
    }
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 7. Laplacian Sharpen（拉普拉斯锐化）
 * 原理：采用带有正中心的拉普拉斯增强核，对图像进行锐化
 */
export async function laplacianSharpen(width: number, height: number, buffer: Uint8Array): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);
  const kernel = [0, -1, 0, -1, 5, -1, 0, -1, 0];
  const kSize = 3, half = 1;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      for (let c = 0; c < 3; c++) {
        let sum = 0;
        for (let ky = -half; ky <= half; ky++) {
          const yy = Math.min(height - 1, Math.max(0, y + ky));
          for (let kx = -half; kx <= half; kx++) {
            const xx = Math.min(width - 1, Math.max(0, x + kx));
            const w = kernel[(ky + half) * kSize + (kx + half)];
            sum += buffer[(yy * width + xx) * 4 + c] * w;
          }
        }
        out[(y * width + x) * 4 + c] = clampToU8(sum);
      }
      out[(y * width + x) * 4 + 3] = buffer[(y * width + x) * 4 + 3];
    }
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 8. UnSharp Mask（原图 + amount*(原图 - 模糊)）
 * 原理：先得到模糊图像，再用原图减去模糊（得到高频）并按比例叠加回原图
 */
export async function unSharpMask(width: number, height: number, buffer: Uint8Array, sigma: number = 1.2,
  amount: number = 1.5): Promise<ImageTaskRe> {
  // 为避免重复读文件，复用 gaussianBlur 的实现：读取 buffer -> 生成 blurred buffer

  const n = width * height;
  const out = new Uint8Array(buffer.length);
  const blurredPm: ImageTaskRe = await gaussianBlur(width, height, buffer, sigma);
  const blurredBuf = blurredPm.out;

  for (let i = 0; i < buffer.length; i += 4) {
    for (let c = 0; c < 3; c++) {
      const orig = buffer[i + c];
      const b = blurredBuf[i + c];
      const v = orig + amount * (orig - b);
      out[i + c] = clampToU8(v);
    }
    out[i + 3] = buffer[i + 3];
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 9. Sobel Edge Enhance（检测边缘并叠加回原图）
 * 原理：Sobel 提取水平/垂直梯度，合成梯度幅值并按强度叠加回原图
 */
export async function sobelEdgeEnhance(width: number, height: number, buffer: Uint8Array,
  edgeStrength: number = 0.3): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);
  const gray = rgbaToGrayUint8(buffer, width, height);
  const gx = [-1, 0, 1, -2, 0, 2, -1, 0, 1];
  const gy = [-1, -2, -1, 0, 0, 0, 1, 2, 1];

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      let sx = 0, sy = 0;
      for (let ky = -1; ky <= 1; ky++) {
        const yy = Math.min(height - 1, Math.max(0, y + ky));
        for (let kx = -1; kx <= 1; kx++) {
          const xx = Math.min(width - 1, Math.max(0, x + kx));
          const val = gray[yy * width + xx];
          sx += val * gx[(ky + 1) * 3 + (kx + 1)];
          sy += val * gy[(ky + 1) * 3 + (kx + 1)];
        }
      }
      const mag = Math.min(255, Math.round(Math.hypot(sx, sy)));
      for (let c = 0; c < 3; c++) {
        const orig = buffer[(y * width + x) * 4 + c];
        out[(y * width + x) * 4 + c] = clampToU8(orig + edgeStrength * mag);
      }
      out[(y * width + x) * 4 + 3] = buffer[(y * width + x) * 4 + 3];
    }
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 10. Canny Edge Detection（简化版）
 * 原理：高斯模糊 -> 计算梯度与方向 -> 非极大值抑制(NMS) -> 双阈值与连接（hysteresis）
 * 注意：此实现为简化版，仅用于演示；性能与参数可调
 */
export async function cannyEdgeDetection(width: number, height: number, buffer: Uint8Array, lowThresh: number,
  highThresh: number): Promise<ImageTaskRe> {

  const n = width * height;
  const blurredPm = await gaussianBlur(width, height, buffer, 1.0);
  const blurredBuf = blurredPm.out;
  const blurredGray = rgbaToGrayUint8(blurredBuf, width, height);

  const gx = new Float32Array(width * height);
  const gy = new Float32Array(width * height);
  const mag = new Float32Array(width * height);
  const ang = new Float32Array(width * height);

  for (let y = 1; y < height - 1; y++) {
    for (let x = 1; x < width - 1; x++) {
      const idx = y * width + x;
      const a00 = blurredGray[(y - 1) * width + (x - 1)];
      const a01 = blurredGray[(y - 1) * width + x];
      const a02 = blurredGray[(y - 1) * width + (x + 1)];
      const a10 = blurredGray[y * width + (x - 1)];
      const a12 = blurredGray[y * width + (x + 1)];
      const a20 = blurredGray[(y + 1) * width + (x - 1)];
      const a21 = blurredGray[(y + 1) * width + x];
      const a22 = blurredGray[(y + 1) * width + (x + 1)];
      const gxv = (a02 + 2 * a12 + a22) - (a00 + 2 * a10 + a20);
      const gyv = (a20 + 2 * a21 + a22) - (a00 + 2 * a01 + a02);
      gx[idx] = gxv;
      gy[idx] = gyv;
      mag[idx] = Math.hypot(gxv, gyv);
      ang[idx] = Math.atan2(gyv, gxv);
    }
  }

  // NMS (approx)
  const edges = new Float32Array(width * height);
  for (let y = 1; y < height - 1; y++) {
    for (let x = 1; x < width - 1; x++) {
      const idx = y * width + x;
      const angle = ang[idx] * (180 / Math.PI);
      let q = 0, r = 0;
      if ((angle >= -22.5 && angle <= 22.5) || angle <= -157.5 || angle >= 157.5) {
        q = mag[idx - 1];
        r = mag[idx + 1];
      } else if ((angle >= 22.5 && angle < 67.5) || (angle <= -112.5 && angle > -157.5)) {
        q = mag[idx - width + 1];
        r = mag[idx + width - 1];
      } else if ((angle >= 67.5 && angle <= 112.5) || (angle <= -67.5 && angle >= -112.5)) {
        q = mag[idx - width];
        r = mag[idx + width];
      } else {
        q = mag[idx - width - 1];
        r = mag[idx + width + 1];
      }
      edges[idx] = (mag[idx] >= q && mag[idx] >= r) ? mag[idx] : 0;
    }
  }

  // double threshold + hysteresis
  const strong = 255, weak = 75;
  const result = new Uint8Array(width * height);
  for (let i = 0; i < width * height; i++) {
    if (edges[i] >= highThresh) {
      result[i] = strong;
    } else if (edges[i] >= lowThresh) {
      result[i] = weak;
    } else {
      result[i] =
        0;
    }
  }

  for (let y = 1; y < height - 1; y++) {
    for (let x = 1; x < width - 1; x++) {
      const idx = y * width + x;
      if (result[idx] === weak) {
        let hasStrong = false;
        for (let ky = -1; ky <= 1; ky++) {
          for (let kx = -1; kx <= 1; kx++) {
            if (result[(y + ky) * width + (x + kx)] === strong) {
              hasStrong = true;
            }
          }
        }
        result[idx] = hasStrong ? strong : 0;
      }
    }
  }

  // output binary edge map as RGBA
  const out = new Uint8Array(width * height * 4);
  for (let i = 0; i < width * height; i++) {
    const v = result[i];
    out[i * 4] = v;
    out[i * 4 + 1] = v;
    out[i * 4 + 2] = v;
    out[i * 4 + 3] = 255;
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 11. CLAHE（局部自适应直方图均衡） - 针对 Y 通道
 * 原理：将图像分块，对每块做直方图均衡并对过多直方图计数剪切（clip limit），最后重建图像
 */
export async function clahe(width: number, height: number, buffer: Uint8Array, tilesX: number, tilesY: number,
  clipLimit: number): Promise<ImageTaskRe> {

  const n = width * height;
  const pixelCount = width * height;

  // convert to YUV-ish
  const Y = new Uint8Array(pixelCount);
  const U = new Float32Array(pixelCount);
  const V = new Float32Array(pixelCount);
  for (let i = 0; i < pixelCount; i++) {
    const r = buffer[i * 4], g = buffer[i * 4 + 1], b = buffer[i * 4 + 2];
    const y = 0.299 * r + 0.587 * g + 0.114 * b;
    const u = -0.168736 * r - 0.331264 * g + 0.5 * b;
    const v = 0.5 * r - 0.418688 * g - 0.081312 * b;
    Y[i] = clampToU8(y);
    U[i] = u;
    V[i] = v;
  }

  const tileW = Math.floor(width / tilesX);
  const tileH = Math.floor(height / tilesY);
  const outY = new Uint8Array(pixelCount);

  for (let ty = 0; ty < tilesY; ty++) {
    for (let tx = 0; tx < tilesX; tx++) {
      const sx = tx * tileW;
      const sy = ty * tileH;
      const ex = (tx === tilesX - 1) ? width : sx + tileW;
      const ey = (ty === tilesY - 1) ? height : sy + tileH;
      const hist: number[] = new Array<number>(256).fill(0);
      for (let y = sy; y < ey; y++) {
        for (let x = sx; x < ex; x++) {
          hist[Y[y * width + x]]++;
        }
      }
      // clip
      let excess = 0;
      for (let i = 0; i < 256; i++) {
        if (hist[i] > clipLimit) {
          excess += (hist[i] - clipLimit);
          hist[i] = clipLimit;
        }
      }
      const add = Math.floor(excess / 256);
      for (let i = 0; i < 256; i++) {
        hist[i] += add;
      }
      // cdf
      const cdf: number[] = new Array<number>(256).fill(0);
      cdf[0] = hist[0];
      for (let i = 1; i < 256; i++) {
        cdf[i] = cdf[i - 1] + hist[i];
      }
      const total = (ex - sx) * (ey - sy);
      const cdfMin = cdf.find(v => v > 0) ?? 0;
      for (let y = sy; y < ey; y++) {
        for (let x = sx; x < ex; x++) {
          const idx = y * width + x;
          const v = Y[idx];
          outY[idx] = total === cdfMin ? v : clampToU8(((cdf[v] - cdfMin) / (total - cdfMin)) * 255);
        }
      }
    }
  }

  // reconstruct RGB
  const out = new Uint8Array(pixelCount * 4);
  for (let i = 0; i < pixelCount; i++) {
    const yv = outY[i];
    const r = yv + 1.402 * V[i];
    const g = yv - 0.344136 * U[i] - 0.714136 * V[i];
    const b = yv + 1.772 * U[i];
    out[i * 4] = clampToU8(r);
    out[i * 4 + 1] = clampToU8(g);
    out[i * 4 + 2] = clampToU8(b);
    out[i * 4 + 3] = buffer[i * 4 + 3];
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 12. Color Balance（按比例缩放 R/G/B）
 * 原理：分别对 R/G/B 乘以系数实现色彩偏移或白平衡
 */
@Concurrent
export async function colorBalance(width: number, height: number, buffer: Uint8Array, rScale: number = 1.05,
  gScale: number = 1.0,
  bScale: number = 1.05): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);

  for (let i = 0; i < n; i++) {
    out[i * 4] = clampToU8(buffer[i * 4] * rScale);
    out[i * 4 + 1] = clampToU8(buffer[i * 4 + 1] * gScale);
    out[i * 4 + 2] = clampToU8(buffer[i * 4 + 2] * bScale);
    out[i * 4 + 3] = buffer[i * 4 + 3];
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 13. Brightness Adjustment（加减常数）
 */
export async function brightnessAdjustment(width: number, height: number, buffer: Uint8Array,
  delta: number = 8): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);
  for (let i = 0; i < n; i++) {
    out[i * 4] = clampToU8(buffer[i * 4] + delta);
    out[i * 4 + 1] = clampToU8(buffer[i * 4 + 1] + delta);
    out[i * 4 + 2] = clampToU8(buffer[i * 4 + 2] + delta);
    out[i * 4 + 3] = buffer[i * 4 + 3];
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 14. Bilateral Filter（边缘保留平滑） - 朴素实现
 * 原理：结合空间和颜色相似度的双边权重做加权平均，保留边缘
 */
function gaussian(x: number, sigma: number) {
  return Math.exp(-(x * x) / (2 * sigma * sigma));
}

export async function bilateralFilter(width: number, height: number, buffer: Uint8Array, diameter: number = 5,
  sigmaColor: number = 20,
  sigmaSpace: number = 5): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);

  const radius = Math.floor(diameter / 2);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      for (let c = 0; c < 3; c++) {
        let wp = 0, sum = 0;
        const center = buffer[(y * width + x) * 4 + c];
        for (let ky = -radius; ky <= radius; ky++) {
          const yy = y + ky;
          if (yy < 0 || yy >= height) {
            continue;
          }
          for (let kx = -radius; kx <= radius; kx++) {
            const xx = x + kx;
            if (xx < 0 || xx >= width) {
              continue;
            }
            const neigh = buffer[(yy * width + xx) * 4 + c];
            const gs = gaussian(Math.hypot(kx, ky), sigmaSpace);
            const gr = gaussian(neigh - center, sigmaColor);
            const w = gs * gr;
            sum += neigh * w;
            wp += w;
          }
        }
        out[(y * width + x) * 4 + c] = clampToU8(sum / (wp || 1));
      }
      out[(y * width + x) * 4 + 3] = buffer[(y * width + x) * 4 + 3];
    }
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

/**
 * 15. Edge Enhancement（自定义卷积核）
 * kernel = [-1,-1,-1; -1,9,-1; -1,-1,-1]
 */
export async function edgeEnhancementCustom(width: number, height: number, buffer: Uint8Array): Promise<ImageTaskRe> {

  const n = width * height;
  const out = new Uint8Array(buffer.length);

  const kernel = [-1, -1, -1, -1, 9, -1, -1, -1, -1];
  const kSize = 3, half = 1;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      for (let c = 0; c < 3; c++) {
        let sum = 0;
        for (let ky = -half; ky <= half; ky++) {
          const yy = Math.min(height - 1, Math.max(0, y + ky));
          for (let kx = -half; kx <= half; kx++) {
            const xx = Math.min(width - 1, Math.max(0, x + kx));
            const w = kernel[(ky + half) * kSize + (kx + half)];
            sum += buffer[(yy * width + xx) * 4 + c] * w;
          }
        }
        out[(y * width + x) * 4 + c] = clampToU8(sum);
      }
      out[(y * width + x) * 4 + 3] = buffer[(y * width + x) * 4 + 3];
    }
  }
  const re: ImageTaskRe = {
    width: width,
    height: height,
    out: out
  }
  return re;
}

