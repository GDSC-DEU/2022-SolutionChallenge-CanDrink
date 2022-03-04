import os
import os.path
import time

import cv2
import numpy as np
import requests
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

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
    driver.get(os.getenv("KEYWORD"))

    driver.execute_cdp_cmd(
        "Page.addScriptToEvaluateOnNewDocument",
        {
            "source": """ 
            Object.defineProperty(navigator, 'webdriver', { 
                get: () => undefined 
            }) 
        """
        },
    )

    time.sleep(2)

    add_more = driver.find_element(By.XPATH, '//*[@id="btfTab"]/ul[1]/li[2]')
    driver.execute_script("arguments[0].click();", add_more)

    add_more = driver.find_element(By.XPATH, '//*[@id="btfTab"]/ul[2]/li[2]/div/div[4]/section[2]/div/ul/li[9]')
    driver.execute_script("arguments[0].click();", add_more)

    while True:
        try:
            driver.find_element(By.CLASS_NAME, "sdp-review__gallery__section__list__more__btn__arrow").click()

            img_datas = driver.find_elements(By.XPATH, "/html/body/div[8]/div[14]/section/div[6]/li/img")

            for img_data in img_datas[len(img_datas) - 30 :]:
                img_url = img_data.get_attribute("src").replace("320", "q-1", 1)
                image_confirm(img_url)
        except:
            break


if __name__ == "__main__":
    driver.implicitly_wait(10)
    make_folder()
    main()
    driver.quit()
