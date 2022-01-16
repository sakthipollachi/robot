*** Settings ***
Library     SeleniumLibrary

*** Test Cases ***

ADVPBADAB-18268
    ${options}    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Run Keyword    Call Method    ${options}    add_argument    --headless
    Run Keyword    Call Method    ${options}    add_argument    --no-sandbox
    Run Keyword    Call Method    ${options}    add_argument    --disable-dev-shm-usage
    Create WebDriver    Chrome    chrome_options=${options}
    Go To    https://www.google.com/
    Capture Page Screenshot    
