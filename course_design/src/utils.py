import cv2
import numpy as np
from skimage.feature import local_binary_pattern
from collections import deque


def enhanced_otsu_seeding(img_rgb):
    # Step 1: 转换至LAB空间
    img_lab = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2LAB)
    L, A, B = cv2.split(img_lab)
    
    # Step 2: 加权Otsu全局阈值
    T_global, otsu_thresh = cv2.threshold(L, 0, 255, cv2.THRESH_OTSU)
    # print(f"T_global (calculated): {T_global}")
    # Step 3: 局部方差动态修正
    window_size = 50
    local_var = cv2.boxFilter(L**2, -1, (window_size, window_size)) - cv2.boxFilter(L, -1, (window_size, window_size))**2
    T_local = np.where(local_var > 100, T_global * 1.2, T_global)
    # print(f"T_local:{T_local}")
    # Step 4: 颜色相似性筛选
    mean_A = cv2.mean(A)[0]
    mean_B = cv2.mean(B)[0]
    delta_E = np.sqrt((A - mean_A)**2 + (B - mean_B)**2)
    # print(f"deltaE:{delta_E}")
    # cv2.imwrite("otsu_thresh.png", otsu_thresh)
    # cv2.imwrite("delta_E.png", delta_E)
    # cv2.imwrite("L.png", L)
    # cv2.imwrite("T_local.png", T_local)
    # cv2.imwrite("thresh1.png", (L > T_local) * 255)
    # cv2.imwrite("thresh2.png", (delta_E < 15) * 255)
    
    seeds = (L > T_local) & (delta_E < 15)
    
    # Step 5: 形态学优化
    # cv2.imwrite("seeds_before.png", seeds * 255)
    kernel = cv2.getStructuringElement(cv2.MORPH_CROSS, (3,3))
    seeds = cv2.erode(seeds.astype(np.uint8), kernel)
    # cv2.imwrite("seeds_after.png", seeds * 255)
    # 连通区域过滤
    _, labels = cv2.connectedComponents(seeds)
    for label in np.unique(labels):
        if label == 0: continue
        mask = labels == label
        density = np.sum(mask) / (np.prod(mask.shape))
        if density < 0.001: seeds[mask] = 0
    # print(np.any(seeds))
    # cv2.imwrite("seeds.png", seeds * 255)
    return seeds

def compute_lbp_texture(image_gray):
    # 使用 uniform LBP
    lbp = local_binary_pattern(image_gray, P=8, R=1, method='uniform')
    return lbp

def region_growing_with_texture_and_edges(image, seeds, color_thresh=40, texture_thresh=3.0):
    H, W, _ = image.shape
    visited = np.zeros((H, W), dtype=bool)
    output_mask = np.zeros((H, W), dtype=np.uint8)

    # 颜色转 Lab 空间更鲁棒
    image_lab = cv2.cvtColor(image, cv2.COLOR_RGB2Lab)
    gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)

    # 提取纹理
    lbp = compute_lbp_texture(gray)

    # 边缘检测
    filtered = cv2.bilateralFilter(gray, d=5, sigmaColor=25, sigmaSpace=25)
    edges = cv2.Canny(filtered, 100, 150)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    edges_closed = cv2.morphologyEx(edges, cv2.MORPH_CLOSE, kernel)
    
    combined_edges = edges_closed
    # combined_edges = edges
    # cv2.imwrite("edges_result.png", combined_edges)
    # cv2.imwrite("filtered.png", filtered)


    # 方向：四邻域
    directions = [(-1,0), (1,0), (0,-1), (0,1)]

    for seed in seeds:
        y, x = seed
        seed_color = image_lab[y, x].astype(np.float32)
        seed_texture = lbp[y, x]

        region_colors = [seed_color]
        region_textures = [seed_texture]

        queue = deque()
        queue.append((x, y))
        visited[y, x] = True
        output_mask[y, x] = 1

        while queue:
            cx, cy = queue.popleft()
            for dx, dy in directions:
                nx, ny = cx + dx, cy + dy
                if 0 <= nx < W and 0 <= ny < H and not visited[ny, nx]:
                    if combined_edges[ny, nx] > 0:
                        continue 
                    color = image_lab[ny, nx]
                    texture = lbp[ny, nx]

                    mean_color = np.mean(region_colors, axis=0)
                    mean_texture = np.mean(region_textures)

                    color_dist = np.linalg.norm(color - mean_color)
                    texture_dist = abs(texture - mean_texture)

                    if color_dist < color_thresh and texture_dist < texture_thresh:
                        visited[ny, nx] = True
                        output_mask[ny, nx] = 1
                        region_colors.append(color)
                        region_textures.append(texture)
                        queue.append((nx, ny))
    # cv2.imwrite("region_grow_result.png", output_mask * 255)
    return output_mask

def morphological_refinement(mask):
    """自适应形态学后处理"""
    # 计算前景区域面积
    area = cv2.countNonZero(mask)
    
    # 动态选择结构元素尺寸
    kernel_size = max(2, int(np.sqrt(area)/200))
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (kernel_size, kernel_size))
    
    # 分步处理
    # 步骤1: 闭运算填充小孔洞
    closed = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=1)
    
    # 步骤2: 开运算去除孤立噪声
    opened = cv2.morphologyEx(closed, cv2.MORPH_OPEN, kernel, iterations=1)
    refined = opened
    # 步骤3: 边缘敏感膨胀
    # edges = cv2.Canny(opened, 100, 200)
    # dilated = cv2.dilate(opened, kernel, iterations=3)
    # refined = np.where(edges>0, opened, dilated)  # 保留原始边缘
    # cv2.imwrite("refined.png", refined * 255)
    return refined