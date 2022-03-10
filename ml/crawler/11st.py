import os
import time

import cv2
import numpy as np
import requests
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from tqdm import tqdm

from util.driver import driver


def frame_switch(name: str) -> None:
    while True:
        try:
            if name == "default":
                driver.switch_to.default_content()
            else:
                driver.switch_to.frame(name)
            break
        except:
            pass


def make_folder():
    global save_dir
    save_dir = os.path.join("data", os.getenv("NAME"))
    if not os.path.isdir(save_dir):
        os.makedirs(save_dir)


def image_confirm(img_url: str):
    image_nparray = np.asarray(bytearray(requests.get(img_url).content), dtype=np.uint8)
    image = cv2.imdecode(image_nparray, cv2.IMREAD_COLOR)

    if image.shape[0] > 1280 or image.shape[1] > 720:
        image_resize = cv2.resize(image, dsize=(0, 0), fx=0.5, fy=0.5, interpolation=cv2.INTER_LINEAR)
        image = image_resize

    cv2.imshow("Image", image)
    input = cv2.waitKey(0)

    if input == int(os.getenv("KEY")):
        dirListing = os.listdir(save_dir)
        cv2.imwrite(os.path.join(save_dir, f"{str(len(dirListing)+1)}.png"), image)


def main():
    driver.get(os.getenv("KEYWORD"))  # 크롤링 링크
    time.sleep(3)
    frame_switch("ifrmReview")

    add_more = driver.find_element(By.XPATH, '//*[@id="allPhotoReviewList"]')
    driver.execute_script("arguments[0].click();", add_more)

    frame_switch("default")

    followers_panel = driver.find_element(By.XPATH, '//*[@id="photo-review-scroll"]')

    count = 0
    while True:
        try:
            img_datas = driver.find_elements(By.XPATH, '//*[@id="photo-review-paged-list"]/li/button')
            before = len(img_datas)

            if count > 5:
                break
            driver.execute_script("arguments[0].scrollTop = arguments[0].scrollHeight", followers_panel)

            time.sleep(0.1)

            img_datas = driver.find_elements(By.XPATH, '//*[@id="photo-review-paged-list"]/li/button')

            if len(img_datas) <= before:
                count += 1
            else:
                count = 0
        except:
            count += 1

    img_datas = driver.find_elements(By.XPATH, '//*[@id="photo-review-paged-list"]/li/button')

    for img_data in tqdm(img_datas):
        img_url = img_data.get_attribute("style").split('"')[1].replace("400X400", "1999x1999", 1)
        image_confirm(img_url)


if __name__ == "__main__":
    driver.implicitly_wait(10)
    make_folder()
    main()
    driver.quit()
