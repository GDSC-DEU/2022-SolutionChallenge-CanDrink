from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager

chrome_options = webdriver.ChromeOptions()

user_agent = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.93 Safari/537.36"
)
chrome_options.add_argument("user-agent=" + user_agent)
chrome_options.add_argument("--disable-blink-features=AutomationControlled")
chrome_options.add_argument("headless")
chrome_options.add_argument("--start-maximized")
chrome_options.add_experimental_option("excludeSwitches", ["enable-logging"])
chrome_options.page_load_strategy = "none"


driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)
