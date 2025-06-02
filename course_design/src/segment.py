import cv2
from utils import *
import os
import time


def main():
    # 读取输入图像
    input_folder = "EFG_BPP_package\images"
    output_folder = "result"
    # 确保输出文件夹存在
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    processing_times = []
    # 遍历输入文件夹中的所有文件
    for file_name in os.listdir(input_folder):
        # 构造完整的文件路径
        input_path = os.path.join(input_folder, file_name)
        # print(input_path)
        output_path = os.path.join(output_folder, file_name)

    # img_name = "2084"
    # img_type = "png"
    # img_path = r"EFG_BPP_package\images" + "\\" + img_name + "." + img_type
        img = cv2.imread(input_path)
        # img_lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)  
        


        start_time = time.time()
        # 设置种子点
        # h, w = img_rgb.shape[:2]
        # window_sizes = [3,5,7]
        seeds = enhanced_otsu_seeding(img_rgb)
        seeds_coordinates = np.argwhere(seeds == 1)

        # grower = ParallelRegionGrower(img_lab, integral_L)
        # result = grower.multi_scale_growing(seeds_coordinates)

        # grower = AdvancedRegionGrower(delta_e=300, contrast_diff=200, window_size=7)
        # result = grower.grow(img_rgb, seeds_coordinates)
        denoised = cv2.GaussianBlur(img_rgb, (5, 5), sigmaX=1.0)
        # denoised_bgr = cv2.cvtColor(denoised, cv2.COLOR_RGB2BGR)
        # cv2.imwrite("denoised.png", denoised_bgr)
        result = region_growing_with_texture_and_edges(denoised, seeds_coordinates)

        refined = morphological_refinement(result)
        
        end_time = time.time()
        cv2.imwrite(output_path, refined * 255)

        processing_time = end_time - start_time
        processing_times.append(processing_time)
        print(f"Processed {file_name} in {processing_time:.2f} seconds")
        
    mean_time = np.mean(processing_times)
    std_time = np.std(processing_times)
    print(f"Average processing time: {mean_time:.2f} seconds")
    print(f"Standard deviation of processing time: {std_time:.2f} seconds")
        # cv2.imwrite(output_path, refined * 255)
    # # 可视化结果
    # cv2.imshow("Result", result)
    # cv2.waitKey(0)

    # 可视化结果
    # plt.figure(figsize=(6, 6))
    # plt.subplot(2, 2, 1)
    # plt.title("Original Image")
    # plt.imshow(img_rgb)
    # plt.axis("off")

    # plt.subplot(2, 2, 2)
    # plt.title("Enhanced Otsu Seeding Result")
    # plt.imshow(seeds, cmap="gray")
    # plt.axis("off")

    # plt.subplot(2, 2, 3)
    # plt.title("Region Grow Result")
    # plt.imshow(result)
    # plt.axis("off")

    # plt.subplot(2, 2, 4)
    # plt.title("Refined Result")
    # plt.imshow(refined)
    # plt.axis("off")


    # plt.tight_layout()
    # plt.show()



if __name__ == '__main__':
    # execution_time = timeit.timeit(main, number=1)
    # print(f"Total execution time: {execution_time:.2f} seconds")
    main()