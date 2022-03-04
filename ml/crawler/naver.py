import os
import time

import cv2
import numpy as np
import requests
from selenium.webdriver import ActionChains
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from tqdm import tqdm

from util.driver import driver


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
    driver.get(f'https://search.naver.com/search.naver?where=image&sm=tab_jum&query={os.getenv("KEYWORD")}')
    while True:
        is_end = driver.find_element(By.XPATH, '//*[@id="main_pack"]/section[2]/div/div[1]/div[2]').get_attribute(
            "style"
        )
        driver.execute_script("window.scrollTo(0,document.body.scrollHeight)")
        if is_end == "display: none;":
            break

    img_datas = driver.find_elements(By.XPATH, '//*[@id="main_pack"]/section[2]/div/div[1]/div[1]/div/div/div[1]/a/img')
    for img_data in tqdm(img_datas):
        adress = img_data.get_attribute("src")
        if adress == "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7":
            action = ActionChains(driver)
            action.move_to_element(img_data).perform()
            time.sleep(1)
            adress = img_data.get_attribute("src")
        image_confirm(adress[: adress.index("type") - 1])


if __name__ == "__main__":
    driver.implicitly_wait(10)
    make_folder()
    main()
    driver.quit()
