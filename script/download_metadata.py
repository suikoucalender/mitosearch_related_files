import time
from selenium import webdriver
from selenium.webdriver.common.by import By

# Chromeのオプション
options = webdriver.ChromeOptions()
# options.add_argument("--start-maximized")

# Selenium Serverに接続
driver = webdriver.Remote(command_executor='http://localhost:4444/wd/hub', options=options)

# driver = webdriver.Chrome()

# DBCLS SRAにGETメソッドでリクエストを送信
driver.get("https://sra.dbcls.jp/result.html?target_db=sra&term=mifish&rows=100&sort=Updated&order=desc")
time.sleep(5)

# cssタグを指定して、プロジェクトを取得
pjts_selector = ".tabulator-cell[tabulator-field='_id']"
#projects = driver.find_elements_by_css_selector(pjts_selector) #ver3までの書き方
projects = driver.find_elements(By.CSS_SELECTOR, pjts_selector)

# NCBI SRAで検索するための文字列を作成
search_str = ""
for pjt in projects:
  search_str = search_str + " or " + pjt.text

search_str = search_str.replace(" or ", "", 1)
print(search_str)

#driver = webdriver.Remote(command_executor='http://localhost:4444/wd/hub', options=options)
driver.get("https://www.ncbi.nlm.nih.gov/sra/?term=" + search_str)

time.sleep(10)

# send toボタンをクリック
driver.execute_script('document.getElementById("sendto").click();')
time.sleep(5)

# Choose Destination → Fileを選択 
driver.execute_script('document.getElementById("dest_File").click();')
time.sleep(5)

# Format → Accession Listを選択
driver.execute_script('document.getElementById("file_format").options[2].setAttribute("selected", "selected")')
time.sleep(5)

# Create Fileをクリック
driver.execute_script('document.querySelector("#submenu_File > button").click();')
time.sleep(15)

driver.quit()
